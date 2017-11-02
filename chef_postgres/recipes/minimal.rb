# frozen_string_literal: true

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "master" # opts: master, standby

codename = node["chef_postgres"]["release_apt_codename"]
version = node["chef_postgres"]["version"]

include_recipe "chef_postgres::log_output"

::Chef::Log.info("** Install essential build tools **")

package "software-properties-common" do
  options "--no-install-recommends"
end

package "build-essential" do
  options "--no-install-recommends"
end

package "pkg-config" do
  options "--no-install-recommends"
end

package "git" do
  options "--no-install-recommends"
end

package "libproj-dev" do
  options "--no-install-recommends"
end

package "liblwgeom-dev" do
  options "--no-install-recommends"
end

::Chef::Log.info("** Setting up apt_repository to get access to the latest PG versions **")

apt_repository "apt.postgresql.org" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{codename}-pgdg"
  components ["main", version]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  action :add
end

package "postgresql-#{version}"
package "postgresql-client-#{version}"
package "postgresql-server-dev-#{version}"
package "postgresql-contrib-#{version}"

include_recipe "chef_postgres::config_postgres"

pg_pass = node["chef_postgres"]["vars"]["pg_pass"]
admin_user = node["chef_postgres"]["vars"]["admin_user"]
admin_pass = node["chef_postgres"]["vars"]["admin_pass"]
admin_is_generated = node["chef_postgres"]["vars"]["admin_is_generated"]
repl_user = node["chef_postgres"]["vars"]["repl_user"]
repl_pass = node["chef_postgres"]["vars"]["repl_pass"]
backup_dir = node["chef_postgres"]["pg_config"]["backup_directory"]

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