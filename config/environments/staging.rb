require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Full error reports are enabled
  config.consider_all_requests_local = true

  # See everything in the log (default is :info)
  config.log_level = :info

  config.active_support.deprecation = :log

  config.cache_store = :redis_store, {
    url: "redis://mymaster/6",
    role: "master",
    sentinels: Rails.application.secrets[:redis_hosts].split(";").map { |host| { host: host,  port: 26379 } },
    namespace: "cache",
    expires_in: 1.days
  }
end
