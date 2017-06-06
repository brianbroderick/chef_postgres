require "digest"

version = node['postgresql']['version']

first_letter = ['a','b','c','d','e','f'][rand(6)] # has to start with a letter
admin_user_default = first_letter + ::Digest::MD5.hexdigest(rand.to_s)[0,9]
admin_pass_default = ::Digest::MD5.hexdigest(rand.to_s)

node.default['postgresql']['admin_login']['username'] = admin_user_default
node.default['postgresql']['admin_login']['password'] = admin_pass_default

admin_user = node['postgresql']['admin_login']['username']
admin_pass = node['postgresql']['admin_login']['password']

include_recipe 'chef_postgres::apt_repo'

Chef::Log.info("** Installing Postgres **")

package "postgresql-#{version}"
package "postgresql-client-#{version}"
package "postgresql-server-dev-#{version}"
package "postgresql-contrib-#{version}"

Chef::Log.info("** Copying Files **")

cookbook_file "Copy pg_hba" do  
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/pg_hba.conf"
  source "pg_hba.conf"  
end

cookbook_file "Copy postgres.conf" do  
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/postgresql.conf"
  source "postgresql.conf"  
end

Chef::Log.info("** Starting Postgres **")

service "Start Postgres" do
  action :restart
  service_name "postgresql"  
end

bash "create_ops_user" do
  user "postgres"
  code <<-EOH
  echo "CREATE USER #{admin_user} WITH PASSWORD '#{admin_pass}' SUPERUSER CREATEDB CREATEROLE; CREATE DATABASE #{admin_user} OWNER #{admin_user};" | psql -U postgres -d postgres
  EOH
  action :run  
end

# Only run this, if generating the info through the defaults.
file "Record admin info when using generated info" do
  content "user: #{admin_user} password: #{admin_pass}"
  group "root"
  mode "0400"
  owner "root"
  path "/etc/postgresql/#{version}/main/admin_login"
end if admin_pass_default == admin_pass
