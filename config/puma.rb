#!/usr/bin/env puma

if ENV['RAILS_ENV'] != 'development'
  deploy_to = '/var/www/novo-educacao'

  bind "unix://#{deploy_to}/shared/tmp/sockets/puma.sock"
  directory "#{deploy_to}/current"
  rackup "#{deploy_to}/current/config.ru"
  pidfile "#{deploy_to}/shared/tmp/pids/puma.pid"
  state_path "#{deploy_to}/shared/tmp/sockets/puma.state"
  activate_control_app "unix://#{deploy_to}/shared/tmp/sockets/pumactl.sock"

  stdout_redirect "#{deploy_to}/current/log/puma.stdout.log",
    "#{deploy_to}/current/log/puma.stderr.log",
    true

  on_restart do
    puts 'Refreshing Gemfile'
    ENV["BUNDLE_GEMFILE"] = "#{deploy_to}/current/Gemfile"
  end
end

if ENV['RAILS_ENV'] == 'development'
  worker_timeout 10000
end

environment ENV['RAILS_ENV']
threads 1,1
workers ENV.fetch('PUMA_WORKERS', 4)

preload_app!
prune_bundler

# Required for preload_app!
on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect!
end
