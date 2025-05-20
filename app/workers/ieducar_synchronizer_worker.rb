class IeducarSynchronizerWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: 3, dead: false, queue: :critical

  sidekiq_retries_exhausted do |msg, exception|
    entity_id, synchronization_id = msg['args']

    Entity.find(entity_id).using_connection do
      synchronization = IeducarApiSynchronization.find(synchronization_id)
      synchronization.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        exception.message
      )
    end

    Honeybadger.notify(exception)
  end

  def perform(entity_id = nil, synchronization_id = nil, full_synchronization = false, current_years = true)
    if entity_id.present? && synchronization_id.present?
      perform_for_entity(
        Entity.find(entity_id),
        synchronization_id,
        current_years
      )
    else
      all_entities.each do |entity|
        entity.using_connection do
          Rails.logger.info "[IeducarSynchronizerWorker] Iniciando sincronização para o cliente #{entity.name} - #{entity.name}"

          entity.using_connection do
            configuration = IeducarApiConfiguration.current

            unless configuration.persisted?
              Rails.logger.warn "[IeducarSynchronizerWorker] Configuração ausente para o cliente #{entity.name} - #{entity.name}"
              next
            end

            configuration.start_synchronization(User.first, entity.name, full_synchronization, current_years)

            Rails.logger.info "[IeducarSynchronizerWorker] Sincronização agendada para o cliente #{entity.name} - #{entity.name}"
          end
        end
      end
    end
  end

  private

  def perform_for_entity(entity, synchronization_id, current_years)
    entity.using_connection do
      synchronization = IeducarApiSynchronization.started.find_by(id: synchronization_id)

      break unless synchronization.try(:started?)

      UnitiesSynchronizerWorker.set(
        queue: synchronization.full_synchronization? ? :synchronizer_full : :synchronizer
      ).perform_async(
        entity_id: entity.id,
        synchronization_id: synchronization.id,
        current_years: current_years
      )
    end
  end

  def all_entities
    Entity.enable_to_sync
  end
end
