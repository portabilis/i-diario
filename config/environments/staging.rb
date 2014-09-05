require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are enabled and caching is turned of
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # See everything in the log (default is :info)
  config.log_level = :debug

  config.active_support.deprecation = :log
end
