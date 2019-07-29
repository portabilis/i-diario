$REDIS_DB = if Rails.application.secrets[:redis_url]
              Redis.new(url: Rails.application.secrets[:redis_url])
            else
              Redis.new
            end
