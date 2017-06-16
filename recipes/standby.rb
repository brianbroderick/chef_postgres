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
  EOF_CBB
  notifies :run, "ruby_block[log_unzip_base_backup]", :before
end
