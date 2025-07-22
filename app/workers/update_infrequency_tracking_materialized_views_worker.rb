class UpdateInfrequencyTrackingMaterializedViewsWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :low,
                  on_conflict: { client: :log, server: :reject }

  def perform(database)
    entity = Entity.where("config @> hstore('database', ?)", database).first

    entity.using_connection do
      connection = ActiveRecord::Base.connection
      connection.execute('REFRESH MATERIALIZED VIEW mvw_infrequency_tracking_students')
      connection.execute('REFRESH MATERIALIZED VIEW mvw_infrequency_tracking_classrooms')
    end
  end
end
