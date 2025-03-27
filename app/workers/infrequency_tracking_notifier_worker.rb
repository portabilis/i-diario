class EntityNotFoundError < StandardError; end

class InfrequencyTrackingNotifierWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id)
    entity = Entity.find_by(id: entity_id)

    unless entity
      error = EntityNotFoundError.new("Entity com o id #{entity_id} não foi encontrado")
      log_and_notify_error(error)
      raise error
    end

    entity.using_connection do
      InfrequencyTrackingNotifier.notify!
    end
  end

  private

  def log_and_notify_error(error)
    Rails.logger.warn("Error occurred: #{error.class} - #{error.message}")
    Honeybadger.notify(error)
  end
end
