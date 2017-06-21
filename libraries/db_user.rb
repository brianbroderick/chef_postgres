# frozen_string_literal: true
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
        node.default["chef_postgres"][login]["username"] = admin_user_default
        node.default["chef_postgres"][login]["password"] = admin_pass_default
      end

      def call
        [admin_user, admin_pass, generated_user?]
      end

      def first_letter
        @first_letter ||= %w(a b c d e f)[rand(6)]
      end

      def admin_user_default
        # user names have to start with a letter
        @admin_user_default ||= first_letter + ::Digest::MD5.hexdigest(seed)[0, 9]
      end

      def admin_pass_default
        @admin_pass_default ||= ::Digest::SHA1.hexdigest(seed)
      end

      def admin_user
        @admin_user ||= node["chef_postgres"][login]["username"]
      end

      def admin_pass
        @admin_pass ||= node["chef_postgres"][login]["password"]
      end

      def generated_user?
        admin_pass_default == admin_pass
      end

      def seed # takes an average of 0.039 seconds to run on a MacBook Pro
        1.upto(1000+rand(1000)).reduce("") do |accum, _|
          accum << random_letters(rand(30)) + rand.to_s
          accum
        end
      end   

      def random_letters(num=1)
        1.upto(num).reduce("") do |accum, _|
          accum << %w(a b c d e f g h i j k l m n o p q r s t u v w x y z ! , @ # $ % ^ & * - _ + = ~)[rand(40)]
          accum
        end
      end         
    end
  end
end
