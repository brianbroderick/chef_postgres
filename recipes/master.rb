# frozen_string_literal: true
chef_gem "aws-sdk" do
  compile_time true
end
require "aws-sdk"

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "master" # opts: master, standby

include_recipe "chef_postgres::log_output"
include_recipe "chef_postgres::ubuntu_packages"
include_recipe "chef_postgres::config_postgres"
include_recipe "chef_postgres::security"

version = node["chef_postgres"]["version"]
pg_pass = node["chef_postgres"]["vars"]["pg_pass"]
admin_user = node["chef_postgres"]["vars"]["admin_user"]
admin_pass = node["chef_postgres"]["vars"]["admin_pass"]
admin_is_generated = node["chef_postgres"]["vars"]["admin_is_generated"]
repl_user = node["chef_postgres"]["vars"]["repl_user"]
repl_pass = node["chef_postgres"]["vars"]["repl_pass"]
backup_dir = node["chef_postgres"]["pg_config"]["backup_directory"]

# Build this on the master so the standbys have the right settings
template "recovery_conf.source" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "#{node["chef_postgres"]["pg_config"]["data_directory"]}/recovery_conf.source"
  source "recovery_conf.erb"
  variables({ config: { username: repl_user,
                        password: repl_pass,
                        hostname: node["ec2"]["local_hostname"],
                        standby: node["chef_postgres"]["pg_config"]["cluster_type"] } })
end

bash "move_data_directory" do
  action :run
  code <<-EOF_MDD
  echo "Moving data directory" >> /tmp/chef_setup.log
  TIME_DELAY = 0.1
  WAITED = 0
  until [ ! -f /var/lib/postgresql/#{version}/main/postmaster.pid ]; do
    sleep $TIME_DELAY
    $WAITED = $(($WAITED + $TIME_DELAY))
    echo "Waiting for Postgres to Stop. Waited: $WAITED seconds" >> /tmp/chef_setup.log
    if [ $WAITED -gt 15 ]
    then
      echo "Waiting long enough..." >> /tmp/chef_setup.log
      break
    fi
  done
  mv /var/lib/postgresql/#{version}/main/* #{node["chef_postgres"]["pg_config"]["data_directory"]}
  EOF_MDD
  not_if { ::File.exist?("#{node["chef_postgres"]["pg_config"]["data_directory"]}/PG_VERSION") }
  only_if { node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] }
  user "postgres"
  notifies :run, "ruby_block[log_move_data_directory]", :before
end

service "start_postgres" do
  action :start
  service_name "postgresql"
  notifies :run, "ruby_block[log_start_pg]", :before
end

bash "create_admin_user" do
  action :run
  user "postgres"
  code <<-EOF_CAU
    echo "ALTER USER postgres WITH PASSWORD '#{pg_pass}';" | psql -U postgres -d postgres
    echo "CREATE USER #{admin_user} WITH PASSWORD '#{admin_pass}' SUPERUSER CREATEDB CREATEROLE; CREATE DATABASE #{admin_user} OWNER #{admin_user};" | psql -U postgres -d postgres
  EOF_CAU
  notifies :run, "ruby_block[log_create_admin]", :before
end

# Only run this, if generating the info through the defaults.
file "record_admin" do
  content "user: #{admin_user} password: #{admin_pass}"
  group "root"
  mode "0400"
  owner "root"
  path "/etc/postgresql/#{version}/main/admin_login"
  action :create
  only_if { admin_is_generated }
end

bash "create_repl_user" do
  user "postgres"
  code <<-EOF_CRU
  echo "CREATE USER #{repl_user} WITH PASSWORD '#{repl_pass}' REPLICATION LOGIN CONNECTION LIMIT 4;" | psql -U postgres -d postgres
  EOF_CRU
  action :run
  notifies :run, "ruby_block[log_create_repl]", :before
end

bash "create_base_backup" do
  code <<-EOF_CBB
  rm -rf #{backup_dir}/base_backup/*
  pg_basebackup -d 'host=localhost user=#{repl_user} password=#{repl_pass}' -D #{backup_dir}/base_backup --xlog-method=stream
  tar -czf #{backup_dir}/base_backup.tgz #{backup_dir}/base_backup/
  EOF_CBB
  action :run
  notifies :run, "ruby_block[log_create_base_backup]", :before
end

ruby_block "s3_upload_backup" do
  block do
    ::Chef::Provider::UploadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        source: "#{backup_dir}/base_backup.tgz" })
  end
end
