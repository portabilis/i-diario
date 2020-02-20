require 'sidekiq'
require 'sidekiq/web'

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == ["admin", (Rails.application.secrets[:sidekiq_password] || "Sidekiq_123")]
end
Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]

Sidekiq::Extensions.enable_delay!
