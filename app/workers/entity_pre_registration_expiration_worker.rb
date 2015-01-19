class EntityPreRegistrationExpirationWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily.hour_of_day(2) }

  def perform
    Entity.find_each do |entity|
      entity.using_connection do
        PreRegistrationExpiration.expire!
      end
    end
  end
end
