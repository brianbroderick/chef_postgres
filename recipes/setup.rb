node.default['chef_postgres']['config']['data_directory_on_separate_drive'] = true
node.default['chef_postgres']['release_apt_codename'] = "xenial"
node.default['chef_postgres']['version'] = "9.6"
node.default['chef_postgres']['workload'] = "oltp"

codename = node['chef_postgres']['release_apt_codename']
version = node['chef_postgres']['version']

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

template "postgresql.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/postgresql.conf"
  source "postgresql_conf.erb" 
  variables config: ::Chef::Provider::PgConfig.call(node)
end

# cookbook_file "Copy postgres.conf" do  
#   group "postgres"
#   mode "0640"
#   owner "postgres"
#   path "/etc/postgresql/#{version}/main/postgresql.conf"
#   source "postgresql.conf"  
# end

Chef::Log.info("** Starting Postgres **")

service "Start Postgres" do
  action :restart
  service_name "postgresql"  
end

Chef::Log.info("** Create Admin User **")

admin_user, admin_pass, is_generated_user = ::Chef::Provider::DbUser.call(node)

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
end if is_generated_user
