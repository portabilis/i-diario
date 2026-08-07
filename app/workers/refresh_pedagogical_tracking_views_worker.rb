class RefreshPedagogicalTrackingViewsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low,
                  retry: 3,
                  dead: false

  sidekiq_retries_exhausted do |job, exception|
    entity_id, remaining_entity_ids = job['args']

    Rails.logger.error(
      "[refresh_pedagogical_tracking] entity_id=#{entity_id} " \
      "desistindo após retries: #{exception.class}: #{exception.message}"
    )
    Honeybadger.notify(exception, context: { entity_id: entity_id })

    enqueue_next(remaining_entity_ids)
  end

  VIEWS = %w[
    mvw_frequency_by_school_classroom_teachers
    mvw_content_record_by_school_classroom_teachers
  ].freeze

  def self.enqueue_next(remaining_entity_ids)
    next_entity_id, *remaining = Array(remaining_entity_ids)

    if next_entity_id.blank?
      Rails.logger.info('[refresh_pedagogical_tracking] cadeia concluída')

      return
    end

    perform_async(next_entity_id, remaining)
  end

  def perform(entity_id, remaining_entity_ids = [])
    entity = Entity.active.find_by(id: entity_id)

    if entity
      entity.using_connection do
        VIEWS.each { |view| refresh(entity, view) }
      end
    else
      Rails.logger.warn(
        "[refresh_pedagogical_tracking] entity_id=#{entity_id} ignorada: inativa ou inexistente"
      )
    end

    self.class.enqueue_next(remaining_entity_ids)
  end

  private

  def refresh(entity, view)
    started_at = Time.current

    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW #{view}")

    Rails.logger.info(
      "[refresh_pedagogical_tracking] entity=#{entity.name} view=#{view} " \
      "duracao=#{(Time.current - started_at).round(1)}s"
    )
  end
end
