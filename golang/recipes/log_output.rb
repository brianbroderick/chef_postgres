ruby_block "install_codedeploy" do
  block { ::Chef::Log.info("** Installing Codedeploy **") }
  action :nothing
end

ruby_block "install_golang" do
  block { ::Chef::Log.info("** Installing Golang **") }
  action :nothing
end

ruby_block "add_golang_to_profile" do
  block { ::Chef::Log.info("** Adding Golang PATH to profile **") }
  action :nothing
end







