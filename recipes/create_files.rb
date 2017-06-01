file "Create a file" do
  content "<html>This is a placeholder for the home page.</html>"
  group "root"
  mode "0755"
  owner "ubuntu"
  path "/tmp/create-directory-demo/index.html"
end

cookbook_file "Copy a file" do  
  group "root"
  mode "0755"
  owner "ubuntu"
  path "/tmp/create-directory-demo/hello.txt"
  source "hello.txt"  
end
