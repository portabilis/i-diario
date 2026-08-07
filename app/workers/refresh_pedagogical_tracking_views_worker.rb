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

  VIEWS = [
    MvwFrequencyBySchoolClassroomTeacher,
    MvwContentRecordBySchoolClassroomTeacher
  ].map(&:table_name).freeze

  LOCK_TIMEOUT = '10min'.freeze

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
    concurrently = populated?(view)

    with_lock_timeout do
      ActiveRecord::Base.connection.execute(refresh_statement(view, concurrently))
    end

    MaterializedViewRefresh.register!(view)

    Rails.logger.info(
      "[refresh_pedagogical_tracking] entity=#{entity.name} view=#{view} " \
      "modo=#{concurrently ? 'concurrently' : 'exclusivo'} " \
      "duracao=#{(Time.current - started_at).round(1)}s"
    )
  end

  # Duas atualizações da mesma view se esperam sem limite de tempo: sem o timeout,
  # uma cadeia que alcança outra em andamento ficaria parada sem erro e sem log.
  def with_lock_timeout
    connection = ActiveRecord::Base.connection

    connection.execute("SET lock_timeout = '#{LOCK_TIMEOUT}'")

    yield
  ensure
    connection.execute('SET lock_timeout = DEFAULT')
  end

  # CONCURRENTLY não bloqueia as leituras do dashboard, mas o Postgres o recusa
  # em view ainda não populada — caso de base restaurada só com a estrutura.
  def refresh_statement(view, concurrently)
    "REFRESH MATERIALIZED VIEW #{concurrently ? 'CONCURRENTLY ' : ''}#{view}"
  end

  def populated?(view)
    connection = ActiveRecord::Base.connection

    ActiveRecord::Type::Boolean.new.cast(
      connection.select_value(
        'SELECT relispopulated FROM pg_class ' \
        "WHERE relkind = 'm' AND relname = #{connection.quote(view)}"
      )
    ).present?
  end
end
