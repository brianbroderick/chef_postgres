instance = search("aws_opsworks_instance").first
os = instance["os"]

if os == "Red Hat Enterprise Linux 7"
  Chef::Log.info("********** Operating system is Red Hat Enterprise Linux. **********")
elsif os == "Ubuntu 12.04 LTS" || os == "Ubuntu 14.04 LTS" || os == "Ubuntu 16.04 LTS"
  Chef::Log.info("********** Operating system is Ubuntu. **********") 
elsif os == "Microsoft Windows Server 2012 R2 Base"
  Chef::Log.info("********** Operating system is Windows. **********")
elsif os == "Amazon Linux 2015.03" || os == "Amazon Linux 2015.09" || os == "Amazon Linux 2016.03" || os == "Amazon Linux 2016.09" || os == "Amazon Linux 2017.03"
  Chef::Log.info("********** Operating system is Amazon Linux. **********")
elsif os == "CentOS Linux 7"
  Chef::Log.info("********** Operating system is CentOS 7. **********")
else
  Chef::Log.info("********** Cannot determine operating system. **********")
end

case os
when "Ubuntu 12.04 LTS", "Ubuntu 14.04 LTS", "Ubuntu 16.04 LTS"
  apt_package "Install a package with apt-get" do
    package_name "tree"
  end
when "Amazon Linux 2015.03", "Amazon Linux 2015.09", "Amazon Linux 2016.03", "Amazon Linux 2016.09", "Amazon Linux 2017.03", "Red Hat Enterprise Linux 7", "CentOS Linux 7"
  yum_package "Install a package with yum" do
    package_name "tree"
  end
else
  Chef::Log.info("********** Cannot determine operating system type, or operating system is not Linux. Package not installed. **********")
end
