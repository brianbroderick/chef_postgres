include_recipe "asdf::log_output"

cron "copybackupstosaturn.sh" do
  minute "0"
  hour "9"
  user "ubuntu"
  command "/code/bin/copybackupstosaturn.sh"
end
