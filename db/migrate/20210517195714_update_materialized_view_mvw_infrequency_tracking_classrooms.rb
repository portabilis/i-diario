class UpdateMaterializedViewMvwInfrequencyTrackingClassrooms < ActiveRecord::Migration
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW mvw_infrequency_tracking_classrooms;

      CREATE MATERIALIZED VIEW mvw_infrequency_tracking_classrooms AS
      SELECT classrooms.id AS id,
             classrooms.description AS description,
             classrooms.year AS year,
             classrooms.unity_id AS unity_id
        FROM infrequency_trackings
        JOIN classrooms
          ON classrooms.id = infrequency_trackings.classroom_id
    GROUP BY classrooms.id, classrooms.description, classrooms.year, classrooms.unity_id;
    SQL
  end
end
