include_recipe "asdf::log_output"

bash "install_erlang" do  
  cwd  "#{node['asdf']['ubuntu_home_dir']}"
  code "#{node["asdf"]["asdf_location"]} install erlang 20.0
        #{node["asdf"]["asdf_location"]} global erlang 20.0"
  notifies :run, "ruby_block[install_erlang]", :before      
end

bash "install_elixir" do  
  cwd  "#{node['asdf']['ubuntu_home_dir']}"
  code "#{node["asdf"]["asdf_location"]} install elixir 1.5.1
        #{node["asdf"]["asdf_location"]} global elixir 1.5.1"
  notifies :run, "ruby_block[install_elixir]", :before      
end

bash "install_ruby" do  
  cwd  "#{node['asdf']['ubuntu_home_dir']}"
  code "#{node["asdf"]["asdf_location"]} install ruby 2.4.2
        #{node["asdf"]["asdf_location"]} global ruby 2.4.2"
  notifies :run, "ruby_block[install_ruby]", :before       
end
