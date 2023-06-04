class UpdateMaterializedViewMvwInfrequencyTrackingClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW mvw_infrequency_tracking_classrooms;

      CREATE MATERIALIZED VIEW mvw_infrequency_tracking_classrooms AS
      SELECT classrooms.id AS id,
             classrooms.description AS description,
             classrooms.year AS year,
             classrooms_grades.grade_id AS grade_id,
             classrooms.unity_id AS unity_id
        FROM infrequency_trackings
        JOIN classrooms
          ON classrooms.id = infrequency_trackings.classroom_id
        JOIN classrooms_grades
          ON classrooms_grades.classroom_id = classrooms.id
    GROUP BY classrooms.id, classrooms.description, classrooms.year, classrooms_grades.grade_id, classrooms.unity_id;
    SQL
  end
end
