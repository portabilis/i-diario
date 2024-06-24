def redis_dev
  $REDIS_DB = nil

  Sidekiq.configure_server do |config|
    config.redis = nil
  end
end

def configure_redis
  if Rails.application.secrets[:REDIS_URL].blank? || Rails.application.secrets[:REDIS_DB_SIDEKIQ].blank?
    raise "Redis URL or DB sidekiq is not set in secrets"
  end

  if Rails.application.secrets[:REDIS_MODE] == 'sentinel'
    redis_sentinels = Rails.application.secrets[:REDIS_SENTINELS]

    if redis_sentinels.blank?
      raise "Redis sentinels are not set in secrets"
    end

    config_redis = {
      url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_SIDEKIQ]}",
      role: "master",
      sentinels: redis_sentinels.split(";").map { |host| { host: host, port: 26379 }}
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
end

if Rails.env.test? || Rails.env.development?
  redis_dev
else
  configure_redis
end
