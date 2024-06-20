def redis_dev
  $REDIS_DB = nil

  Sidekiq.configure_server do |config|
    config.redis = nil
  end
end

def configure_redis
  redis_url = Rails.application.secrets[:REDIS_URL]
  redis_db_sidekiq = Rails.application.secrets[:REDIS_DB_SIDEKIQ]

  if redis_url.blank? || redis_db_sidekiq.blank?
    raise "Redis URL or DB sidekiq is not set in secrets"
  end

  if Rails.application.secrets[:REDIS_MODE] == 'sentinel'
    redis_sentinels = Rails.application.secrets[:REDIS_SENTINELS]

    if redis_sentinels.blank?
      raise "Redis sentinels are not set in secrets"
    end

    config_redis = {
      url: "#{redis_url}#{redis_db_sidekiq}",
      role: "master",
      sentinels: redis_sentinels.split(";").map { |host| { host: host, port: 26379 }}
    }
  else
    config_redis = {
      url: "#{redis_url}#{redis_db_sidekiq}"
    }
  end

  $REDIS_DB = Redis.new(config_redis)

  Sidekiq.configure_server do |config|
    config.redis = config_redis
  end
end

if Rails.env.test? || Rails.env.development?
  redis_dev
else
  configure_redis
end
