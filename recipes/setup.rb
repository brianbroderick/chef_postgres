node.default['postgresql']['pgdg']['release_apt_codename'] = "xenial"
node.default['postgresql']['version'] = "9.6"

codename = node['postgresql']['pgdg']['release_apt_codename']
version = node['postgresql']['version']

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
  action :start
  service_name "postgresql"  
end