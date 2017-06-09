### Using 'notifies' on a lot of the directives since PG deletes a pid when it's stopped.  
### This was causing issues when moving the data directory.  
### notifies, along with a ruby_block that waits until the pid is deleted fixes the issue.

node.default['chef_postgres']['release_apt_codename'] = "xenial"
node.default['chef_postgres']['version'] = "9.6"
node.default['chef_postgres']['workload'] = "oltp"
# node.default['chef_postgres']['pg_config']['data_drive'] = "/mnt/data"

codename = node['chef_postgres']['release_apt_codename']
version = node['chef_postgres']['version']

node.default['chef_postgres']['pg_config']['data_directory_on_separate_drive'] = true
node.default['chef_postgres']['pg_config']['data_directory'] = if node['chef_postgres']['pg_config']['data_directory_on_separate_drive']
                                                                 "/mnt/data/postgresql/#{version}/main"
                                                               else
                                                                 "/var/lib/postgresql/#{version}/main"
                                                               end

::Chef::Log.info("** Setting up apt_repository to get access to the latest PG versions **")

apt_repository 'apt.postgresql.org' do
 uri 'http://apt.postgresql.org/pub/repos/apt'
 distribution "#{codename}-pgdg"
 components ['main', version]
 key 'https://www.postgresql.org/media/keys/ACCC4CF8.asc'
 action :add 
end

::Chef::Log.info("** Installing Postgres **")

package "postgresql-#{version}"
package "postgresql-client-#{version}"
package "postgresql-server-dev-#{version}"
package "postgresql-contrib-#{version}"

# Create data directory
directory node['chef_postgres']['pg_config']['data_directory'] do
  owner 'postgres'
  group 'postgres'
  mode '0700'
  recursive true
  action :create
  only_if { node['chef_postgres']['pg_config']['data_directory_on_separate_drive'] }
  notifies :run, 'ruby_block[log_data_directory]', :before
end

cookbook_file "Copy pg_hba" do  
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/pg_hba.conf"
  source "pg_hba.conf" 
  notifies :run, 'ruby_block[log_copy_files]', :before
end

template "postgresql.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/postgresql.conf"
  source "postgresql_conf.erb" 
  variables config: ::Chef::Provider::PgConfig.call(node)
end

service "Stop Postgres" do
  action :stop
  service_name "postgresql"  
  notifies :run, 'ruby_block[log_stop_pg]', :before
  notifies :run, 'ruby_block[wait_for_pg_stop]', :immediately
end

ruby_block 'wait_for_pg_stop' do
  block do
    attempts = 0
    until !::File.exist?("/var/lib/postgresql/#{version}/main/postmaster.pid") do
      attempts += 1
      ::Chef::Log.info("** Waiting for Postgres to Stop. Attempts: #{attempts.to_s} **")
      sleep(0.1) 
      if attempts >= 150
        ::Chef::Log.info("** Waited 15 seconds... moving on. **")
        break
      end      
    end      
  end
  action :nothing
  notifies :run, 'bash[move_data_directory]', :immediately
end

bash "move_data_directory" do
  code <<-EOF_MDD    
  mv /var/lib/postgresql/#{version}/main/* #{node['chef_postgres']['pg_config']['data_directory']}
  EOF_MDD
  not_if { ::File.exist?("#{node['chef_postgres']['pg_config']['data_directory']}/PG_VERSION") }
  only_if { node['chef_postgres']['pg_config']['data_directory_on_separate_drive'] }
  user "postgres"  
  action :nothing
  notifies :run, 'ruby_block[log_move_data_directory]', :before
  notifies :start, 'service[start_postgres]', :immediately  
end

service "start_postgres" do
  action :nothing
  service_name "postgresql"  
  notifies :run, 'ruby_block[log_start_pg]', :before
  notifies :run, 'bash[create_ops_user]', :immediately  
end

admin_user, admin_pass, is_generated_user = ::Chef::Provider::DbUser.call(node)

bash "create_ops_user" do
  user "postgres"
  code <<-EOF_COU
  echo "CREATE USER #{admin_user} WITH PASSWORD '#{admin_pass}' SUPERUSER CREATEDB CREATEROLE; CREATE DATABASE #{admin_user} OWNER #{admin_user};" | psql -U postgres -d postgres
  EOF_COU
  action :nothing  
  notifies :run, 'ruby_block[log_create_admin]', :before
  notifies :create, 'file[record_admin]', :immediately     
end

# Only run this, if generating the info through the defaults.
file "record_admin" do
  content "user: #{admin_user} password: #{admin_pass}"
  group "root"
  mode "0400"
  owner "root"
  path "/etc/postgresql/#{version}/main/admin_login"
  action :nothing
end if is_generated_user

### Logging ###

ruby_block 'log_data_directory' do
  block { ::Chef::Log.info("** Creating Data Directory **") }
  action :nothing
end

ruby_block 'log_copy_files' do
  block { ::Chef::Log.info("** Copying Files **") }
  action :nothing
end

ruby_block 'log_stop_pg' do
  block { ::Chef::Log.info("** Stop Postgres **") }
  action :nothing
end

ruby_block 'log_move_data_directory' do
  block { ::Chef::Log.info("** Moving Data Directory **") }
  action :nothing
end

ruby_block 'log_start_pg' do
  block { ::Chef::Log.info("** Starting Postgres **") }
  action :nothing
end

ruby_block 'log_create_admin' do
  block { ::Chef::Log.info("** Create Admin User **") }
  action :nothing
end