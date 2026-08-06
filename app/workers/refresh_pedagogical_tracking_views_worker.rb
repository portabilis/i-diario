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

  VIEWS = [
    MvwFrequencyBySchoolClassroomTeacher,
    MvwContentRecordBySchoolClassroomTeacher
  ].map(&:table_name).freeze

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
    concurrently = populated?(view)

    ActiveRecord::Base.connection.execute(refresh_statement(view, concurrently))

    MaterializedViewRefresh.register!(view)

    Rails.logger.info(
      "[refresh_pedagogical_tracking] entity=#{entity.name} view=#{view} " \
      "modo=#{concurrently ? 'concurrently' : 'exclusivo'} " \
      "duracao=#{(Time.current - started_at).round(1)}s"
    )
  end

  # CONCURRENTLY não bloqueia as leituras do dashboard durante a atualização,
  # mas o Postgres o recusa em view ainda não populada (ex.: primeira carga de
  # uma base nova) — nesse caso usa o refresh exclusivo.
  def refresh_statement(view, concurrently)
    "REFRESH MATERIALIZED VIEW #{concurrently ? 'CONCURRENTLY ' : ''}#{view}"
  end

  def populated?(view)
    connection = ActiveRecord::Base.connection

    ActiveRecord::Type::Boolean.new.cast(
      connection.select_value(
        "SELECT relispopulated FROM pg_class WHERE relname = #{connection.quote(view)}"
      )
    )
  end
end
