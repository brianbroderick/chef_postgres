# Block more than 4 attempts from a particular IP address per minute
bash "iptables_ssh" do
  action :run
  code <<-EOF_ISH 
  iptables --flush
  iptables -N LOGDROP
  iptables -A LOGDROP -j LOG
  iptables -A LOGDROP -j DROP
  iptables -I INPUT -p tcp --dport 22 -i eth0 --syn -m recent --set
  iptables -I INPUT -p tcp --dport 22 -i eth0 --syn -m recent --update --seconds 60 --hitcount 4 -j LOGDROP
  EOF_ISH
  notifies :run, "ruby_block[log_set_iptables]", :before
end

# iptables -I INPUT -p tcp --dport 22 -i eth0 -m state --state NEW -m recent --set
# iptables -I INPUT -p tcp --dport 22 -i eth0 -m state --state NEW -m recent  --update --seconds 60 --hitcount 4 -j LOGDROP
 