
desc "Refreshes materialized views used in the pedagogical tracking dashboard"
task refresh_pedagogical_tracking_views: :environment do
  Entity.active.each do |entity|
    entity.using_connection do
      connection = ActiveRecord::Base.connection
      connection.execute('REFRESH MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers')
      connection.execute('REFRESH MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers')

      expire_school_days_cache(entity.id)
    end
  end

  def expire_school_days_cache(entity_id)
    cache_prefix = "pedagogical_trackings:entity_#{entity_id}"

    Rails.cache.delete_matched("#{cache_prefix}:*")
  end
end
