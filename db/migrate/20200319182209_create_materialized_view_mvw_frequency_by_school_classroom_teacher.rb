class CreateMaterializedViewMvwFrequencyBySchoolClassroomTeacher < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers AS
      SELECT daily_frequencies.frequency_date AS frequency_date,
             unities.id AS unity_id,
             unities.name AS unity,
             classrooms.id AS classroom_id,
             classrooms.description AS classroom,
             teachers.id AS teacher_id,
             teachers.name AS teacher,
             now() AS last_refresh
        FROM daily_frequencies
        JOIN classrooms
          ON classrooms.id = daily_frequencies.classroom_id
        JOIN unities
          ON unities.id = classrooms.unity_id
        JOIN teachers
          ON teachers.id = daily_frequencies.owner_teacher_id;
    SQL
  end
end
