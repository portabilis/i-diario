unless Rails.env.test? || Rails.env.development?
  if (Rails.application.secrets[:REDIS_MODE] == 'sentinel')
    config_redis = {
      url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_SIDEKIQ]}",
      role: "master",
      sentinels: Rails.application.secrets[:REDIS_SENTINELS].split(";").map { |host| { host: host,  port: 26379 }}
    }
  else
    config_redis = {
      url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_SIDEKIQ]}"
    }
  end

  $REDIS_DB = Redis.new(config_redis)

  Sidekiq.configure_server do |config|
    config.redis = config_redis
  end

  Sidekiq.configure_client do |config|
    config.redis = config_redis
  end
end
