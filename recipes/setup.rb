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

node.default['chef_postgres']['pg_config']['cluster_type'] = "hot_standby"  # opts: standalone, warm_standby, hot_standby    
node.default['chef_postgres']['pg_config']['pg_node'] = "master" # opts: master, standby                                                           

admin_user, admin_pass, admin_is_generated = ::Chef::Provider::DbUser.call(node, "admin_login")   
repl_user, repl_pass, repl_is_generated = ::Chef::Provider::DbUser.call(node, "repl_login")                                                            

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

service "stop_postgres" do
  action :stop
  service_name "postgresql"  
  notifies :run, 'ruby_block[log_stop_pg]', :before  
end

directory node['chef_postgres']['pg_config']['data_directory'] do
  owner 'postgres'
  group 'postgres'
  mode '0700'
  recursive true
  action :create
  only_if { node['chef_postgres']['pg_config']['data_directory_on_separate_drive'] }
  notifies :run, 'ruby_block[log_data_directory]', :before
end

template "pg_hba.conf" do  
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/pg_hba.conf"
  source "pg_hba_conf.erb"
  variables config: { repl_user: repl_user } 
  notifies :run, 'ruby_block[log_copy_files]', :before
end

template "postgresql.conf" do
  group "postgres"
  mode "0640"
  owner "postgres"
  path "/etc/postgresql/#{version}/main/postgresql.conf"
  source "postgresql_conf.erb" 
  variables config: { optimization: ::Chef::Provider::PgConfig.call(node),
                      repl: { cluster_type: node['chef_postgres']['pg_config']['cluster_type'],
                              pg_node: node['chef_postgres']['pg_config']['pg_node'] } 
                    } 
end

# ## Wait for PG to fully stop and remove its PID
# attempts = 0
# if ::File.exist?("/var/lib/postgresql/#{version}/main/postmaster.pid")
#   ::Chef::Log.info("** Waiting for Postgres to Stop. **")
# end
# until !::File.exist?("/var/lib/postgresql/#{version}/main/postmaster.pid") do
#   attempts += 1
#   sleep(0.1) 
#   ::Chef::Log.info("** Waiting for Postgres to Stop. Waited: #{(attempts * 0.1).to_s} seconds **")  
#   if attempts >= 150
#     ::Chef::Log.info("** Waited 15 seconds... moving on. **")
#     break
#   end      
# end 

bash "move_data_directory" do
  code <<-EOF_MDD  
  echo "** Moving data directory **" >> "/etc/postgresql/#{version}/main/setup.log 
  TIME_DELAY = 0.1
  WAITED = 0  
  until [ ! -f /var/lib/postgresql/#{version}/main/postmaster.pid ]; do
    sleep $TIME_DELAY
    $WAITED = $(($WAITED + $TIME_DELAY))    
    echo "** Waiting for Postgres to Stop. Waited: $WAITED seconds **" >> "/etc/postgresql/#{version}/main/setup.log
    if [ $WAITED -gt 15 ] 
    then
      echo "** Waiting long enough... **" >> "/etc/postgresql/#{version}/main/setup.log
      break
    fi
  done 
  mv /var/lib/postgresql/#{version}/main/* #{node['chef_postgres']['pg_config']['data_directory']}
  EOF_MDD
  not_if { ::File.exist?("#{node['chef_postgres']['pg_config']['data_directory']}/PG_VERSION") }
  only_if { node['chef_postgres']['pg_config']['data_directory_on_separate_drive'] }
  user "postgres"    
  action :run
  notifies :run, 'ruby_block[log_move_data_directory]', :before  
end

service "start_postgres" do
  action :start
  service_name "postgresql"  
  notifies :run, 'ruby_block[log_start_pg]', :before  
end

bash "create_admin_user" do
  user "postgres"
  code <<-EOF_CAU
  echo "CREATE USER #{admin_user} WITH PASSWORD '#{admin_pass}' SUPERUSER CREATEDB CREATEROLE; CREATE DATABASE #{admin_user} OWNER #{admin_user};" | psql -U postgres -d postgres
  EOF_CAU
  action :run
  notifies :run, 'ruby_block[log_create_admin]', :before  
end

# Only run this, if generating the info through the defaults.
file "record_admin" do
  content "user: #{admin_user} password: #{admin_pass}"
  group "root"
  mode "0400"
  owner "root"
  path "/etc/postgresql/#{version}/main/admin_login"  
  action :create
end if admin_is_generated

bash "create_repl_user" do
  user "postgres"
  code <<-EOF_CRU
  echo "CREATE USER #{repl_user} WITH PASSWORD '#{repl_pass}' REPLICATION LOGIN CONNECTION LIMIT 4;" | psql -U postgres -d postgres
  EOF_CRU
  action :run
  notifies :run, 'ruby_block[log_create_repl]', :before  
end

# Only run this, if generating the info through the defaults.
file "record_repl" do
  content "user: #{repl_user} password: #{repl_pass}"
  group "root"
  mode "0400"
  owner "root"
  path "/etc/postgresql/#{version}/main/repl_login"  
  action :create
end if repl_is_generated

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

ruby_block 'log_create_repl' do
  block { ::Chef::Log.info("** Create Repl User **") }
  action :nothing
end