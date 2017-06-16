# frozen_string_literal: true

node.default["chef_postgres"]["pg_config"]["cluster_type"] = "hot_standby" # opts: standalone, warm_standby, hot_standby
node.default["chef_postgres"]["pg_config"]["pg_node"] = "standby" # opts: master, standby

include_recipe "chef_postgres::setup"