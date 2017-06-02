codename = node['postgresql']['pgdg']['release_apt_codename'] || "xenial"
version = node['postgresql']['version'] || "9.6"

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