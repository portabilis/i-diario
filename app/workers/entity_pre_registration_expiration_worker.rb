class EntityPreRegistrationExpirationWorker
  include Sidekiq::Worker

  def perform
    Entity.find_each do |entity|
      entity.using_connection do
        PreRegistrationExpiration.expire!
      end
    end
  end
end
