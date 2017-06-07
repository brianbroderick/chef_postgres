require "digest"

class Chef
  class Provider 
    class DbUser < Chef::Provider::LWRPBase
      attr_reader :node

      def self.call(*args)
        new(*args).call
      end    

      def initialize(node)
        @node = node
        node.default['chef_postgres']['admin_login']['username'] = admin_user_default
        node.default['chef_postgres']['admin_login']['password'] = admin_pass_default
      end  

      def call
        admin_user, admin_pass
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
  end
end

