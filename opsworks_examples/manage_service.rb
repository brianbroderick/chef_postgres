# frozen_string_literal: true
service "Manage a service" do
  action :stop
  service_name "cron"
end
