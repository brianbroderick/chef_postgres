# Options:
#   :region
#   :file
#   :bucket
#   :access_key_id     - aws credentials
#   :secret_access_key - aws credentials

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
          region: opts[:region],
          access_key_id: opts[:access_key_id],
          secret_access_key: opts[:secret_access_key]
        )
        file = opts[:file]
        bucket = opts[:bucket]
        
        name = ::File.basename(file)
        obj = s3.bucket(bucket).object(name)
        obj.upload_file(file)
      end
    end
  end
end
