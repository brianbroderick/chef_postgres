# frozen_string_literal: true

chef_gem "aws-sdk" do
  compile_time true
end
require "aws-sdk"

node.default["chef_postgres"]["server_name"] = "default"
node.default["chef_postgres"]["release_apt_codename"] = node["lsb"]["codename"]
node.default["chef_postgres"]["version"] = "9.6"
node.default["chef_postgres"]["rh_version"] = node["chef_postgres"]["version"].gsub(/[^0-9]/, "")
node.default["chef_postgres"]["workload"] = "oltp"

# codename = node["chef_postgres"]["release_apt_codename"]
version = node["chef_postgres"]["version"]

node.default["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"] = true
node.default["chef_postgres"]["pg_config"]["data_directory"] = if node["chef_postgres"]["pg_config"]["data_directory_on_separate_drive"]
                                                                 "/mnt/data/postgresql/#{version}/main"
                                                               else
                                                                 "/var/lib/postgresql/#{version}/main"
                                                               end

_, pg_pass, = ::Chef::Provider::DbUser.call(node, "pg_login")
admin_user, admin_pass, admin_is_generated = ::Chef::Provider::DbUser.call(node, "admin_login")
repl_user, repl_pass, = ::Chef::Provider::DbUser.call(node, "repl_login")

node.default["chef_postgres"]["vars"]["pg_pass"] = pg_pass
node.default["chef_postgres"]["vars"]["admin_user"] = admin_user
node.default["chef_postgres"]["vars"]["admin_pass"] = admin_pass
node.default["chef_postgres"]["vars"]["admin_is_generated"] = admin_is_generated
node.default["chef_postgres"]["vars"]["repl_user"] = repl_user
node.default["chef_postgres"]["vars"]["repl_pass"] = repl_pass
