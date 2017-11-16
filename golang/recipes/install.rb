include_recipe "golang::log_output"

# Cache directory
directory "/root/cache" do
  action :create
  recursive true
end

directory "/home/ubuntu/go" do
  user "ubuntu"
  group "ubuntu"
  action :create
  recursive true
end

bash "install_golang" do
  cwd "/root"
  code "CACHED_DOWNLOAD=\"${HOME}/cache/go#{node['golang']['golang_version']}.linux-amd64.tar.gz\"
  wget --continue --output-document \"${CACHED_DOWNLOAD}\" \"https://storage.googleapis.com/golang/go#{node['golang']['golang_version']}.linux-amd64.tar.gz\"
  tar -xaf \"${CACHED_DOWNLOAD}\" --strip-components=1 --directory \"#{node['golang']['goroot']}\"
  "
  notifies :run, "ruby_block[install_golang]", :before
end

bash "add_golang_to_profile" do
  code "if ! cat /etc/profile | grep -q 'usr/local/go/bin'; then
    echo -e '\nexport PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo -e '\nexport PATH=$PATH:/home/ubuntu/go/bin' >> /etc/profile
  fi"
  notifies :run, "ruby_block[add_golang_to_profile]", :before
end


# mkdir -p "${GOROOT}"
# wget --continue --output-document "${CACHED_DOWNLOAD}" "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz"
#
# check if already added
# if cat /etc/profile | grep -q "bashrc"; then echo "hi mom"; fi
