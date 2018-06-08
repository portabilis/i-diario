require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Full error reports are enabled
  config.consider_all_requests_local = true

  # See everything in the log (default is :info)
  config.log_level = :debug

  config.active_support.deprecation = :log

  config.action_mailer.default_url_options = { :host => 'clientetest.portabilis.com.br' }

  config.logger = GELF::Logger.new("***REMOVED***", 12203, "WAN", facility: "novo-educacao-staging")
end
