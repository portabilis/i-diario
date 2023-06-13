class RecreateMaterializedViewMvwFrequencyBySchoolClassroomTeachers < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DROP MATERIALIZED VIEW mvw_frequency_by_school_classroom_teachers;

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
        JOIN unity_school_days
          ON unity_school_days.unity_id = unities.id
         AND unity_school_days.school_day = daily_frequencies.frequency_date
        JOIN teachers
          ON teachers.id = daily_frequencies.owner_teacher_id
        JOIN teacher_discipline_classrooms
          ON teacher_discipline_classrooms.teacher_id = daily_frequencies.owner_teacher_id
         AND teacher_discipline_classrooms.classroom_id = daily_frequencies.classroom_id
         AND teacher_discipline_classrooms.discipline_id = daily_frequencies.discipline_id
         AND teacher_discipline_classrooms.discarded_at IS NULL
       WHERE daily_frequencies.discipline_id IS NOT NULL

       UNION ALL

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
        JOIN unity_school_days
          ON unity_school_days.unity_id = unities.id
         AND unity_school_days.school_day = daily_frequencies.frequency_date
        JOIN teachers
          ON teachers.id = daily_frequencies.owner_teacher_id
        JOIN teacher_discipline_classrooms
          ON teacher_discipline_classrooms.teacher_id = daily_frequencies.owner_teacher_id
         AND teacher_discipline_classrooms.classroom_id = daily_frequencies.classroom_id
         AND teacher_discipline_classrooms.discarded_at IS NULL
       WHERE daily_frequencies.discipline_id IS NULL
    SQL
  end
end
