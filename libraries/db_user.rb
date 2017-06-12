require "digest"

class Chef
  class Provider 
    class DbUser < Chef::Provider::LWRPBase
      attr_reader :node, :login

      def self.call(*args)
        new(*args).call
      end    

      def initialize(node, login = "admin_login")
        @node = node
        @login = login
        node.default['chef_postgres'][login]['username'] = admin_user_default
        node.default['chef_postgres'][login]['password'] = admin_pass_default
      end  

      def call
        return admin_user, admin_pass, is_generated_user?
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
        @admin_user ||= node['chef_postgres'][login]['username']
      end
      
      def admin_pass
        @admin_pass ||= node['chef_postgres'][login]['password']
      end

      def is_generated_user?
        admin_pass_default == admin_pass
      end
    end
  end
end

