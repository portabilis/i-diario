require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Full error reports are enabled
  config.consider_all_requests_local = true

  # See everything in the log (default is :info)
  config.log_level = :info

  config.active_support.deprecation = :log

  if (Rails.application.secrets[:REDIS_MODE] == 'sentinel')
    config.cache_store = :redis_store, {
      url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_CACHE]}",
      role: "master",
      sentinels: Rails.application.secrets[:REDIS_SENTINELS].split(";").map { |host| { host: host,  port: 26379 }},
      namespace: "cache",
      expires_in: 1.days
    }
  else
    config.cache_store = :redis_store, {
      url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_CACHE]}",
      namespace: "cache",
      expires_in: 1.days
    }
  end
end
