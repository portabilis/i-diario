unless Rails.env.test? || Rails.env.development?
  if (Rails.application.secrets[:REDIS_MODE] == 'sentinel')
    redis_config = {
      servers: [{
        url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_SESSION]}",
        role: "master",
        sentinels: Rails.application.secrets[:REDIS_SENTINELS].split(";").map { |host| { host: host,  port: 26379 }},
        namespace: "sessions",
        expire_after: 2.days
      }],
    }
  else

    redis_config = {
      servers: [{
        url: "#{Rails.application.secrets[:REDIS_URL]}#{Rails.application.secrets[:REDIS_DB_SESSION]}"
      }],
      expire_after: 12.hours,
      key: "_#{Rails.application.class.parent_name.downcase}_session",
      threadsafe: true,
      secure: false
    }
  end

  Rails.application.config.session_store :redis_store, redis_config
end
