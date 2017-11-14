include_recipe "golang::log_output"

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
