# Options:
#   :region
#   :source - source file path
#   :bucket

class Chef
  class Provider 
    class UploadFile < Chef::Provider::LWRPBase
      attr_reader :opts

      def self.call(*args)
        new(*args).call
      end 

      def initialize(opts = {})        
        @opts = opts
      end      

      def call
        s3 = ::Aws::S3::Resource.new(
          region: node['chef_postgres']['s3']['region'],
          access_key_id: node['chef_postgres']['s3']['access_key_id'],
          secret_access_key: node['chef_postgres']['s3']['secret_access_key']
        )
        file = opts[:source]
        bucket = opts[:bucket]
        
        name = ::File.basename(file)
        obj = s3.bucket(bucket).object(name)
        obj.upload_file(file)
      end
    end
  end
end
