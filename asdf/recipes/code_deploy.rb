include_recipe "asdf::log_output"

# uses service but is alot slower than checking for a file
# if ! service --status-all 2>&1 | grep -Fq codedeploy-agent; then
bash "download_codedeploy" do
  environment ({ 'HOME' => ::Dir.home("ubuntu"), 'USER' => "ubuntu" })
  cwd "/root"
  code "if ! [ -f '/etc/init.d/codedeploy-agent' ]; then
    wget https://aws-codedeploy-#{node['asdf']['aws_region']}.s3.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    rm ./install
    service codedeploy-agent start
  fi
  "
  notifies :run, "ruby_block[install_codedeploy]", :before
end

# where the code will live
directory "/code" do
  action :create
  owner "ubuntu"
  group "ubuntu"
  recursive true
end

directory "/mnt/data/backups" do
  action :create
  owner "ubuntu"
  group "ubuntu"
  recursive true
end