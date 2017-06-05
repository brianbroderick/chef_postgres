require "digest"

admin_user_default = ::Digest::MD5.hexdigest(rand.to_s)
admin_pass_default = ::Digest::MD5.hexdigest(rand.to_s)

node.default['postgresql']['pgdg']['release_apt_codename'] = "xenial"
node.default['postgresql']['version'] = "9.6"
node.default['postgresql']['admin_login']['username'] = admin_user_default
node.default['postgresql']['admin_login']['password'] = admin_pass_default

codename = node['postgresql']['pgdg']['release_apt_codename']
version = node['postgresql']['version']
admin_user = node['postgresql']['admin_login']['username']
admin_pass = node['postgresql']['admin_login']['password']

Chef::Log.info("** Setting up apt_repository **")

apt_repository 'apt.postgresql.org' do
 uri 'http://apt.postgresql.org/pub/repos/apt'
 distribution "#{codename}-pgdg"
 components ['main', version]
 key 'https://www.postgresql.org/media/keys/ACCC4CF8.asc'
 action :add
end

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
