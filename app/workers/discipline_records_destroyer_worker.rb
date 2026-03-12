# frozen_string_literal: true

class DisciplineRecordsDestroyerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(entity_id, deletion_id)
    Entity.find(entity_id).using_connection do
      deletion = DisciplineRecordDeletion.find(deletion_id)

      destroyer = Api::DisciplineRecordsDestroyer.new(
        unities: deletion.filters['unities_api_code'],
        courses: deletion.filters['courses_api_code'],
        grades: deletion.filters['grades_api_code'],
        disciplines: deletion.filters['disciplines_api_code'],
        year: deletion.filters['year'],
        user: deletion.filters['user_api_code'],
        deletion: deletion
      )

      total = destroyer.call
      deletion.mark_as_completed!(total)
      send_callback(deletion, success: true, deleted: total)
    rescue StandardError => e
      deletion&.mark_with_error!(e.message)
      send_callback(deletion, success: false, error: e.message) if deletion
      Honeybadger.notify(e)
    end
  end

  private

  def send_callback(deletion, payload)
    return if deletion.operation_id.blank?

    api = IeducarApi::PostComponentBatchCallback.new(IeducarApiConfiguration.current.to_api)
    api.send_post(payload.merge(operation_id: deletion.operation_id))
  rescue StandardError => e
    Rails.logger.error("Callback falhou para deletion##{deletion.id}: #{e.message}")
    Honeybadger.notify(e, context: { deletion_id: deletion.id, operation_id: deletion.operation_id })
  end
end
