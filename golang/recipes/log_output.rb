ruby_block "install_codedeploy" do
  block { ::Chef::Log.info("** Installing Codedeploy **") }
  action :nothing
end

###

ruby_block "global_golang" do
  block { ::Chef::Log.info("** Setting Global Golang **") }
  action :nothing
end

ruby_block "install_golang" do
  block { ::Chef::Log.info("** Installing Golang **") }
  action :nothing
end







