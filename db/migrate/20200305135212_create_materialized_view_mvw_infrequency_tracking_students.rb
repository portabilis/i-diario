class CreateMaterializedViewMvwInfrequencyTrackingStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE MATERIALIZED VIEW mvw_infrequency_tracking_students AS
      SELECT students.id AS id,
             students.name AS name,
             EXTRACT(year FROM infrequency_trackings.notification_date) AS year
        FROM infrequency_trackings
        JOIN students
          ON students.id = infrequency_trackings.student_id
    GROUP BY students.id, students.name, infrequency_trackings.notification_date;
    SQL
  end
end
