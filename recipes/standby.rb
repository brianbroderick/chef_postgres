# frozen_string_literal: true

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "standby" # opts: master, standby

include_recipe "chef_postgres::setup"

ruby_block "s3_download_backup" do
  block do
    ::Chef::Provider::DownloadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        file: "base_backup.tgz",
        destination: "/backups/base_backup.tgz" })
  end
end

bash "unzip_base_backup" do
  code <<-EOF_CBB
  tar -xvzf /backups/base_backup.tgz
  chown -R postgres:postgres /backups/base_backup/
  EOF_CBB
  notifies :run, "ruby_block[log_unzip_base_backup]", :before
end

bash "move_backup_directory" do
  action :run
  code <<-EOF_MDD
  mv /backups/base_backup/recovery_conf.source #{node["chef_postgres"]["pg_config"]["data_directory"]}/recovery.conf
  mv /backups/base_backup/* #{node["chef_postgres"]["pg_config"]["data_directory"]}
  EOF_MDD
  user "postgres"
  notifies :run, "ruby_block[log_move_backup_directory]", :before
end

service "start_postgres" do
  action :start
  service_name "postgresql"
  notifies :run, "ruby_block[log_start_pg]", :before
end
