# frozen_string_literal: true
ruby_block "s3_upload" do
  block do
    ::Chef::Provider::UploadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        source: "/tmp/chef_setup.log" })
  end
end

ruby_block "s3_download" do
  block do
    ::Chef::Provider::DownloadFile.call(node,
      { bucket: node["chef_postgres"]["s3"]["bucket"],
        file: "chef_setup.log",
        destination: "/tmp/downloaded_file" })
  end
end
