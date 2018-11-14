require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Full error reports are enabled
  config.consider_all_requests_local = true

  # See everything in the log (default is :info)
  config.log_level = :info

  config.active_support.deprecation = :log
end
