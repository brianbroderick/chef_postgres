# frozen_string_literal: true
### Redhat Support is incomplete ###

rh_version = node["chef_postgres"]["rh_version"]

directory "/tmp/postgres/config" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end

# Download the PGDG repository RPM as a local file
pgdg_package = "pgdg-centos96-9.6-3.noarch.rpm"
remote_file "/tmp/postgres/config/#{pgdg_package}" do
  source "https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/#{pgdg_package}"
  mode "0644"
end

# Install the PGDG repository RPM from the local file
package pgdg_package.to_s do
  provider Chef::Provider::Package::Rpm
  source "/tmp/postgres/config/#{pgdg_package}"
  action :install
end

::Chef::Log.info("** Installing Postgres **")

package "postgresql#{rh_version}"
package "postgresql#{rh_version}-server"
package "postgresql#{rh_version}-contrib"
package "postgresql#{rh_version}-devel"

# sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb
