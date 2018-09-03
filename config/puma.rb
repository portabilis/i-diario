#!/usr/bin/env puma

workers ENV['RAILS_ENV'] == 'production' ? 16 : 2

# Min and Max threads per worker
threads 1, 1

app_dir = "/var/www/novo-educacao"
shared_dir = "#{app_dir}/shared"

environment ENV['RAILS_ENV']

# Set up socket location
bind "unix://#{app_dir}/shared/tmp/sockets/puma.sock"

# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{app_dir}/shared/tmp/pids/puma.pid"
state_path "#{app_dir}/shared/tmp/sockets/puma.state"
activate_control_app "unix://#{app_dir}/shared/tmp/sockets/pumactl.sock"

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file("#{shared_dir}/config/database.yml")[ENV['RAILS_ENV']])
end
