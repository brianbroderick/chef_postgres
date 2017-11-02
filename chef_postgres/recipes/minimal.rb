# frozen_string_literal: true

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "master" # opts: master, standby

include_recipe "chef_postgres::log_output"

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