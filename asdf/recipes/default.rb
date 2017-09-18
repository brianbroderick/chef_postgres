include_recipe "asdf::log_output"
include_recipe "asdf::ubuntu_packages"

directory "#{node['asdf']['ubuntu_home_dir']}/.asdf" do
  action :create
  owner "ubuntu"
  group "ubuntu"  
  recursive true
end

git "asdf" do
  repository "https://github.com/asdf-vm/asdf.git"
  checkout_branch "v0.3.0"
  destination "#{node['asdf']['ubuntu_home_dir']}/.asdf"
  user "ubuntu"
  enable_checkout false
  action :sync
  notifies :run, "ruby_block[installing_asdf]", :before
end

bash "add_to_bashrc" do  
  user "ubuntu"
  code "echo -e '\n. $HOME/.asdf/asdf.sh' >> #{node['asdf']['ubuntu_home_dir']}/.bashrc
        source #{node['asdf']['ubuntu_home_dir']}/.bashrc"
  notifies :run, "ruby_block[add_asdf_to_bashrc]", :before
end

bash "add_plugins" do
  user "ubuntu"
  code "asdf plugin-add erlang
        asdf plugin-add elixir
        asdf plugin-add ruby"
  notifies :run, "ruby_block[add_plugins]", :before      
end

bash "install_erlang" do
  user "ubuntu"
  code "asdf install erlang 20.0
        asdf global erlang 20.0"
  notifies :run, "ruby_block[install_erlang]", :before      
end

bash "install_elixir" do
  user "ubuntu"
  code "asdf install elixir 1.5.1
        asdf global elixir 1.5.1"
  notifies :run, "ruby_block[install_elixir]", :before      
end

bash "install_ruby" do
  user "ubuntu"
  code "asdf install ruby 2.4.2
        asdf global ruby 2.4.2"
  notifies :run, "ruby_block[install_ruby]", :before       
end
      





