
desc "Refreshes materialized views used in the pedagogical tracking dashboard"
task refresh_pedagogical_tracking_views: :environment do
  Entity.active.each do |entity|
    entity.using_connection do
      connection = ActiveRecord::Base.connection
      connection.execute('REFRESH MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers')
      connection.execute('REFRESH MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers')
    end
  end
end
