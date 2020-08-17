class SchoolCalendarQuery
  def initialize(unity, year = nil)
    @unity = unity
    @year = year
  end

  def school_calendar
    @school_calendar = SchoolCalendar.by_unity_id(unity)
    @school_calendar = @school_calendar.by_year(year) if year.present?

    @school_calendar.ordered.first
  end

  def self.school_calendars_with_data_count
    <<-SQL
      SELECT unities.name AS unity_name,
             'Escola' AS kind,
             school_calendar_steps.step_number AS step,
             school_calendars.step_type_description AS step_name,
             '-' AS classroom,
             school_calendar_steps.start_at AS start_at,
             school_calendar_steps.end_at AS end_at,
             school_calendar_steps.start_date_for_posting AS start_date_for_posting,
             school_calendar_steps.end_date_for_posting AS end_date_for_posting,
             td_avaliations.count AS avaliacoes_criadas,
             td_daily_notes.count AS avaliacoes_lancadas,
             td_conceptual_exams.count AS avaliacoes_conceituais_lancadas,
             td_descriptive_exams.count AS avaliacoes_descritivas_lancadas,
             td_daily_frequencies.count as frequencias_lancadas
        FROM school_calendars
        JOIN school_calendar_steps
          ON school_calendar_steps.school_calendar_id = school_calendars.id
        JOIN unities
          ON unities.id = school_calendars.unity_id,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN avaliations
                  ON avaliations.classroom_id = classrooms.id,
                     step_by_classroom(classrooms.id, avaliations.test_date) AS step
               WHERE classrooms.unity_id = unities.id
                 AND step.step_number = school_calendar_steps.step_number
             ) AS td_avaliations,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN avaliations
                  ON avaliations.classroom_id = classrooms.id
                JOIN daily_notes
                  ON daily_notes.avaliation_id = avaliations.id,
                     step_by_classroom(classrooms.id, avaliations.test_date) AS step
               WHERE classrooms.unity_id = unities.id
                 AND step.step_number = school_calendar_steps.step_number
             ) AS td_daily_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN conceptual_exams
                  ON conceptual_exams.classroom_id = classrooms.id
                 AND conceptual_exams.discarded_at IS NULL
               WHERE classrooms.unity_id = unities.id
                 AND conceptual_exams.step_number = school_calendar_steps.step_number
             ) AS td_conceptual_exams,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN descriptive_exams
                  ON descriptive_exams.classroom_id = classrooms.id
                 AND descriptive_exams.step_number = school_calendar_steps.step_number
               WHERE classrooms.unity_id = unities.id
                 AND EXISTS(
                       SELECT 1
                         FROM descriptive_exam_students
                        WHERE descriptive_exam_students.descriptive_exam_id = descriptive_exams.id
                          AND descriptive_exam_students.discarded_at IS NULL
                          AND COALESCE(descriptive_exam_students.value, '') <> ''
                     )
             ) AS td_descriptive_exams,
      LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN daily_frequencies
                  ON daily_frequencies.classroom_id = classrooms.id,
                     step_by_classroom(classrooms.id, daily_frequencies.frequency_date) AS step
               WHERE classrooms.unity_id = unities.id
                 AND step.step_number = school_calendar_steps.step_number
             ) AS td_daily_frequencies
       WHERE school_calendars.year = $1
      UNION ALL
      SELECT unities.name AS unity_name,
             'Turma' AS kind,
             school_calendar_classroom_steps.step_number AS step,
             school_calendars.step_type_description AS step_name,
             classrooms.description AS classroom,
             school_calendar_classroom_steps.start_at AS start_at,
             school_calendar_classroom_steps.end_at AS end_at,
             school_calendar_classroom_steps.start_date_for_posting AS start_date_for_posting,
             school_calendar_classroom_steps.end_date_for_posting AS end_date_for_posting,
             td_avaliations.count AS avaliacoes_criadas,
             td_daily_notes.count AS avaliacoes_lancadas,
             td_conceptual_exams.count AS avaliacoes_conceituais_lancadas,
             td_descriptive_exams.count AS avaliacoes_descritivas_lancadas,
             td_daily_frequencies.count as frequencias_lancadas
        FROM school_calendars
        JOIN school_calendar_classrooms
          ON school_calendar_classrooms.school_calendar_id = school_calendars.id
        JOIN school_calendar_classroom_steps
          ON school_calendar_classroom_steps.school_calendar_classroom_id = school_calendar_classrooms.id
        JOIN unities
          ON unities.id = school_calendars.unity_id
        JOIN classrooms
          ON classrooms.id = school_calendar_classrooms.classroom_id,
     LATERAL (SELECT COUNT(1) AS count
                FROM avaliations,
                     step_by_classroom(classrooms.id, avaliations.test_date) AS step
               WHERE avaliations.classroom_id = classrooms.id
                 AND step.step_number = school_calendar_classroom_steps.step_number
             ) AS td_avaliations,
     LATERAL (SELECT COUNT(1) AS count
                FROM avaliations
                JOIN daily_notes
                  ON daily_notes.avaliation_id = avaliations.id,
                     step_by_classroom(classrooms.id, avaliations.test_date) AS step
               WHERE avaliations.classroom_id = classrooms.id
                 AND step.step_number = school_calendar_classroom_steps.step_number
             ) AS td_daily_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM conceptual_exams
               WHERE conceptual_exams.classroom_id = classrooms.id
                 AND conceptual_exams.discarded_at IS NULL
                 AND conceptual_exams.step_number = school_calendar_classroom_steps.step_number
             ) AS td_conceptual_exams,
     LATERAL (SELECT COUNT(1) AS count
                FROM descriptive_exams
               WHERE descriptive_exams.classroom_id = classrooms.id
                 AND descriptive_exams.step_number = school_calendar_classroom_steps.step_number
                 AND EXISTS(
                       SELECT 1
                         FROM descriptive_exam_students
                        WHERE descriptive_exam_students.descriptive_exam_id = descriptive_exams.id
                          AND descriptive_exam_students.discarded_at IS NULL
                          AND COALESCE(descriptive_exam_students.value, '') <> ''
                     )
             ) AS td_descriptive_exams,
      LATERAL (SELECT COUNT(1) AS count
             FROM classrooms
             JOIN daily_frequencies
               ON daily_frequencies.classroom_id = classrooms.id,
                  step_by_classroom(classrooms.id, daily_frequencies.frequency_date) AS step
            WHERE classrooms.unity_id = unities.id
              AND step.step_number = school_calendar_classroom_steps.step_number
          ) AS td_daily_frequencies
       WHERE school_calendars.year = $1
    ORDER BY unity_name, kind, classroom, step
    SQL
  end

  private

  attr_accessor :unity, :year
end
