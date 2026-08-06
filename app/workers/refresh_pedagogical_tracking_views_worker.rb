class RefreshPedagogicalTrackingViewsWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { [args.first] },
                  queue: :low,
                  retry: 3,
                  on_conflict: { client: :log, server: :reject }

  # Quando os retries de uma entidade se esgotam, reporta o erro e segue para a
  # próxima — uma base com problema não pode impedir a atualização das demais.
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
    remaining = Array(remaining_entity_ids)

    while remaining.any?
      next_entity_id, *remaining = remaining
      jid = perform_async(next_entity_id, remaining)

      return if jid.present?

      # perform_async retorna nil quando o lock único está em conflito (já existe
      # job dessa entidade em fila ou em execução — ex.: cadeia da noite anterior
      # ainda rodando). A base já está sendo atualizada, então pula para a próxima
      # em vez de interromper a cadeia.
      Rails.logger.warn(
        "[refresh_pedagogical_tracking] entity_id=#{next_entity_id} " \
        'pulado: job já em fila/execução'
      )
    end
  end

  def perform(entity_id, remaining_entity_ids = [])
    entity = Entity.find(entity_id)

    entity.using_connection do
      VIEWS.each { |view| refresh(entity, view) }
    end

    # A continuidade em caso de falha fica no sidekiq_retries_exhausted: se o
    # enfileiramento acontecesse num ensure, cada retry desta entidade criaria
    # uma cadeia duplicada a partir daqui.
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
