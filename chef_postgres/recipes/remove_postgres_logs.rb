include_recipe "chef_postgres::log_output"

cron "remove_postgres_logs.sh" do
  minute "0"
  hour "10"
  user "ubuntu"
  command "/mnt/data/scripts/remove_postgres_logs.sh"
end
