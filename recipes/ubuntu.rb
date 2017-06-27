codename = node["chef_postgres"]["release_apt_codename"]
version = node["chef_postgres"]["version"]

::Chef::Log.info("** Install essential build tools **")

package "software-properties-common" do
  options "--no-install-recommends"
end

package "build-essential" do
  options "--no-install-recommends"
end

package "pkg-config" do
  options "--no-install-recommends"
end

package "git" do
  options "--no-install-recommends"
end

package "libproj-dev" do
  options "--no-install-recommends"
end

package "liblwgeom-dev" do
  options "--no-install-recommends"
end

::Chef::Log.info("** Setting up apt_repository to get access to the latest PG versions **")

apt_repository "apt.postgresql.org" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{codename}-pgdg"
  components ["main", version]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  action :add
end

::Chef::Log.info("** Installing Postgres **")

package "postgresql-#{version}"
package "postgresql-client-#{version}"
package "postgresql-server-dev-#{version}"
package "postgresql-contrib-#{version}"

apt_repository "debian" do
  uri "http://ftp.us.debian.org/debian"
  distribution "testing"
  components ["main", "contrib"]
  key "7638D0442B90D010"
  keyserver "keyserver.ubuntu.com"
  # deb_src true
  action :add
end

service "stop_postgres" do
  action :stop
  service_name "postgresql"
  notifies :run, "ruby_block[log_stop_pg]", :before
end  

package "libprotobuf-c-dev" do
  version "1.2.*"
  options "--no-install-recommends" 
end

directory "/var/lib/apt/lists/" do
  recursive true
  action :delete
end