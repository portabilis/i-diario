if Rails.env.development?
  redis_config = {
    servers: ["#{Rails.application.secrets[:redis_url]}/session"],
    expire_after: 12.hours,
    key: "_#{Rails.application.class.parent_name.downcase}_session",
    threadsafe: true,
    secure: false
  }
else
  redis_config = {
    servers: [{
      url: "redis://mymaster/7",
      role: "master",
      sentinels: Rails.application.secrets[:redis_hosts].split(";").map { |host| { host: host,  port: 26379 } },
      namespace: "sessions"
    }],
    expire_after: 2.days
  }
end

Educacao::Application.config.session_store :redis_store, redis_config