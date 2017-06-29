# frozen_string_literal: true

repl_user = node["chef_postgres"]["vars"]["repl_user"]

directory node["chef_postgres"]["pg_config"]["data_directory"] do
  action :create
  owner "postgres"
  group "postgres"
  mode "0700"
  recursive true
  only_if { node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] }
  notifies :run, "ruby_block[log_data_directory]", :before
end

template "pg_hba.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "#{node["chef_postgres"]["pg_config"]["config_directory"]}/pg_hba.conf"
  source "pg_hba_conf.erb"
  variables({ config: { repl_user: repl_user } })
  notifies :run, "ruby_block[log_copy_files]", :before
end

template "postgresql.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "#{node["chef_postgres"]["pg_config"]["config_directory"]}/postgresql.conf"
  source "postgresql_conf.erb"
  variables({ config: { optimization: ::Chef::Provider::PgConfig.call(node),
                        repl: { cluster_type: node["chef_postgres"]["pg_config"]["cluster_type"],
                                pg_node: node["chef_postgres"]["pg_config"]["pg_node"] } } })
end

directory "/backups/base_backup" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  notifies :run, "ruby_block[log_backup_directory]", :before
end
