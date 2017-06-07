require "digest"

class DbUser < Chef::Recipe
  attr_reader :node, :version

  def self.call(*args)
    new(*args).call
  end    

  def initialize(node)
    @node = node
    @version = node['chef_postgres']['version']
    
    node.default['chef_postgres']['admin_login']['username'] = admin_user_default
    node.default['chef_postgres']['admin_login']['password'] = admin_pass_default
  end  

  def call
    Chef::Log.info("** Create Admin User **")

    Chef::Log.info("u: #{admin_user}")

    # bash "create_ops_user" do
    #   user "postgres"
    #   code <<-EOH
    #   echo "CREATE USER #{admin_user} WITH PASSWORD '#{admin_pass}' SUPERUSER CREATEDB CREATEROLE; CREATE DATABASE #{admin_user} OWNER #{admin_user};" | psql -U postgres -d postgres
    #   EOH
    #   action :run  
    # end

    # # Only run this, if generating the info through the defaults.
    # file "Record admin info when using generated info" do
    #   content "user: #{admin_user} password: #{admin_pass}"
    #   group "root"
    #   mode "0400"
    #   owner "root"
    #   path "/etc/postgresql/#{version}/main/admin_login"
    # end if admin_pass_default == admin_pass
  end 

  def first_letter
    @first_letter ||= ['a','b','c','d','e','f'][rand(6)]
  end
       

  def admin_user_default
    # user names have to start with a letter
    @admin_user_default ||= first_letter + ::Digest::MD5.hexdigest(rand.to_s)[0,9]
  end

  def admin_pass_default
    @admin_pass_default ||= ::Digest::MD5.hexdigest(rand.to_s)
  end

  def admin_user
    @admin_user ||= node['chef_postgres']['admin_login']['username']
  end
  
  def admin_pass
    @admin_pass ||= node['chef_postgres']['admin_login']['password']
  end
  

  
  

end

