Sidekiq.configure_server do |config|
  Sidekiq::Status.configure_server_middleware config, expiration: 24.hours
  Sidekiq::Status.configure_client_middleware config, expiration: 24.hours
end

Sidekiq.configure_client do |config|
  Sidekiq::Status.configure_client_middleware config, expiration: 24.hours
end
