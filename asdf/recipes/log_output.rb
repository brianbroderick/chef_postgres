ruby_block "installing_asdf" do
  block { ::Chef::Log.info("** Installing ASDF **") }
  action :nothing
end

ruby_block "add_asdf_to_bashrc" do
  block { ::Chef::Log.info("** Adding ASDF to bashrc **") }
  action :nothing
end

ruby_block "add_plugins" do
  block { ::Chef::Log.info("** Adding Plugins **") }
  action :nothing
end

ruby_block "install_erlang" do
  block { ::Chef::Log.info("** Installing Erlang **") }
  action :nothing
end

ruby_block "install_elixir" do
  block { ::Chef::Log.info("** Installing Elixir **") }
  action :nothing
end

ruby_block "install_ruby" do
  block { ::Chef::Log.info("** Installing Ruby **") }
  action :nothing
end