#!/usr/bin/env puma

workers ENV['RAILS_ENV'] == 'production' ? 16 : 2

# Min and Max threads per worker
threads 1, 1

if ENV['RAILS_ENV'] == 'development'
  worker_timeout 10000
end

if ENV['RAILS_ENV'] != 'development'
  app_dir = "/var/www/novo-educacao"
  shared_dir = "#{app_dir}/shared"

  environment ENV['RAILS_ENV']

  # Set up socket location
  bind "unix://#{shared_dir}/sockets/puma.sock"

  # Logging
  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

  # Set master PID and state locations
  pidfile "#{shared_dir}/pids/puma.pid"
  state_path "#{shared_dir}/sockets/puma.state"
  activate_control_app "unix://#{shared_dir}/sockets/pumactl.sock"
end

preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end