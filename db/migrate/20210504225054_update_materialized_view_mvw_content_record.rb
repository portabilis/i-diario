class UpdateMaterializedViewMvwContentRecord < ActiveRecord::Migration
  def change
    execute <<-SQL
    DROP MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers;
    CREATE MATERIALIZED VIEW mvw_content_record_by_school_classroom_teachers AS
    SELECT content_records.record_date AS record_date,
             unities.id AS unity_id,
             unities.name AS unity,
             classrooms.id AS classroom_id,
             classrooms.description AS classroom,
             teachers.id AS teacher_id,
             teachers.name AS teacher,
             now() AS last_refresh
      FROM content_records
      JOIN classrooms
        ON classrooms.id = content_records.classroom_id
      JOIN unities
        ON unities.id = classrooms.unity_id
      JOIN teachers
        ON teachers.id = content_records.teacher_id
      JOIN teacher_discipline_classrooms
        ON teacher_discipline_classrooms.teacher_id = content_records.teacher_id
     WHERE teacher_discipline_classrooms.discarded_at IS NOT NULL;
    SQL
  end
end
