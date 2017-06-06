Chef::Log.info("** Setting up apt_repository **")

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