
device = node["chef_postgres"]["data_device"]

execute "format_vol" do
  command "sudo mkfs.ext3 #{device}"
  action :run
  not_if {File.exists?("/mnt/data")}
end
execute "mkdir_mnt" do
  command "sudo mkdir /mnt/data"
  action :run
  not_if {File.exists?("/mnt/data")}
end
mount "/mnt/data" do
  device "#{device}"
  fstype "ext3"
  action [:mount, :enable]
end
