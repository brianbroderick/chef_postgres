include_recipe "asdf::ubuntu_packages"

::Chef::Log.info("** Installing ASDF **")

directory "/home/ubuntu/.asdf" do
  action :create
  owner "ubuntu"
  group "ubuntu"  
  recursive true
end

git "asdf" do
  repository "https://github.com/asdf-vm/asdf.git"
  checkout_branch "v0.3.0"
  destination "/home/ubuntu/.asdf"
  user "ubuntu"
  enable_checkout false
  action :sync
end