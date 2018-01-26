require 'sidekiq'
require 'sidekiq/web'

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == ["admin", (Rails.application.secrets[:sidekiq_password] || "Sidekiq_123")]
end
