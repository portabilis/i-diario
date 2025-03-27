class EntityNotFoundError < StandardError; end

class InfrequencyTrackingNotifierWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id)
    entity = find_entity(entity_id)

    return unless entity

    entity.using_connection do
      general_configuration = GeneralConfiguration.current

      return unless notify_absences?(general_configuration)

      notify_infrequency!
    end
  end

  private

  def find_entity(entity_id)
    entity = Entity.find_by(id: entity_id)
    log_and_notify_error(EntityNotFoundError.new("Entity com o id #{entity_id} não foi encontrada")) unless entity
    entity
  end

  def notify_absences?(general_configuration)
    general_configuration.notify_consecutive_or_alternate_absences
  end

  def notify_infrequency!
    InfrequencyTrackingNotifier.notify!
  end

  def log_and_notify_error(error)
    Rails.logger.warn("Error occurred: #{error.class} - #{error.message}")
    Honeybadger.notify(error)
  end
end
