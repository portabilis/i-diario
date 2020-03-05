class UpdateInfrequencyTrackingMaterializedViewsWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(database)
    entity = Entity.where("config @> hstore('database', ?)", database).first

    entity.using_connection do
      connection = ActiveRecord::Base.connection
      connection.execute('REFRESH MATERIALIZED VIEW mvw_infrequency_tracking_students')
      connection.execute('REFRESH MATERIALIZED VIEW mvw_infrequency_tracking_classrooms')
    end
  end
end
