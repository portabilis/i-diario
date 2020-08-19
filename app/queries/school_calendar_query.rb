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
             td_daily_frequencies.count as frequencias_lancadas,
             td_teaching_plans.count AS planos_de_ensino_criados,
             td_transfer_notes.count AS notas_de_transferencia_criadas,
             td_complementary_exams.count AS avaliacoes_complementares_lancadas,
             td_avaliations_recovery_diary_records.count AS recuperacoes_de_avaliacoes_lancadas,
             td_school_term_recovery_diary_record.count AS recuperacoes_de_etapas_lancadas
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = $1
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = $1
             ) AS td_daily_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN conceptual_exams
                  ON conceptual_exams.classroom_id = classrooms.id
                 AND conceptual_exams.discarded_at IS NULL
               WHERE classrooms.unity_id = unities.id
                 AND conceptual_exams.step_number = school_calendar_steps.step_number
                 AND EXTRACT(YEAR FROM conceptual_exams.recorded_at) = $1
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
                 AND EXTRACT(YEAR FROM descriptive_exams.recorded_at) = $1
             ) AS td_descriptive_exams,
      LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN daily_frequencies
                  ON daily_frequencies.classroom_id = classrooms.id,
                     step_by_classroom(classrooms.id, daily_frequencies.frequency_date) AS step
               WHERE classrooms.unity_id = unities.id
                 AND step.step_number = school_calendar_steps.step_number
                 AND EXTRACT(YEAR FROM daily_frequencies.frequency_date) = $1
             ) AS td_daily_frequencies,
      LATERAL (SELECT COUNT(1) AS count
                 FROM teaching_plans
                WHERE teaching_plans.unity_id = unities.id
                  AND school_calendar_steps.step_number = (
                      CASE
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['first_bimester', 'first_bimester_eja', 'first_trimester', 'first_semester']) THEN 1
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['second_bimester', 'second_bimester_eja', 'second_trimester', 'second_semester']) THEN 2
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['third_bimester', 'third_trimester']) THEN 3
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['fourth_bimester']) THEN 4
                      END
                  )
                  AND teaching_plans.year = $1
          ) AS td_teaching_plans,
      LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN transfer_notes
                   ON transfer_notes.classroom_id = classrooms.id,
                      step_by_classroom(classrooms.id, transfer_notes.recorded_at) AS step
                WHERE classrooms.unity_id = unities.id
                  AND step.step_number = school_calendar_steps.step_number
                  AND EXTRACT(YEAR FROM transfer_notes.recorded_at) = $1
              ) AS td_transfer_notes,
      LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN complementary_exams
                   ON complementary_exams.classroom_id = classrooms.id
                WHERE classrooms.unity_id = unities.id
                  AND complementary_exams.step_number = school_calendar_steps.step_number
                  AND EXTRACT(YEAR FROM complementary_exams.recorded_at) = $1
           ) AS td_complementary_exams,
      LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN avaliations
                   ON avaliations.classroom_id = classrooms.id
                 JOIN avaliation_recovery_diary_records
                   ON avaliation_recovery_diary_records.avaliation_id = avaliations.id,
                      step_by_classroom(classrooms.id, avaliations.test_date) AS step
                WHERE classrooms.unity_id = unities.id
                  AND step.step_number = school_calendar_steps.step_number
                  AND EXTRACT(YEAR FROM avaliations.test_date) = $1
        ) AS td_avaliations_recovery_diary_records,
      LATERAL (SELECT COUNT(1) AS count
                 FROM recovery_diary_records
                 JOIN school_term_recovery_diary_records
                   ON school_term_recovery_diary_records.recovery_diary_record_id = recovery_diary_records.id
                WHERE school_term_recovery_diary_records.step_number = school_calendar_steps.step_number
                AND EXTRACT(YEAR FROM school_term_recovery_diary_records.recorded_at) = $1
              ) AS td_school_term_recovery_diary_record
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
             td_daily_frequencies.count as frequencias_lancadas,
             td_teaching_plans.count AS planos_de_ensino_criados,
             td_transfer_notes.count AS notas_de_transferencia_criadas,
             td_complementary_exams.count AS avaliacoes_complementares_lancadas,
             td_avaliations_recovery_diary_records.count AS recuperacoes_de_avaliacoes_lancadas,
             td_school_term_recovery_diary_record.count AS recuperacoes_de_etapas_lancadas
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = $1
             ) AS td_avaliations,
     LATERAL (SELECT COUNT(1) AS count
                FROM avaliations
                JOIN daily_notes
                  ON daily_notes.avaliation_id = avaliations.id,
                     step_by_classroom(classrooms.id, avaliations.test_date) AS step
               WHERE avaliations.classroom_id = classrooms.id
                 AND step.step_number = school_calendar_classroom_steps.step_number
                 AND EXTRACT(YEAR FROM avaliations.test_date) = $1
             ) AS td_daily_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM conceptual_exams
               WHERE conceptual_exams.classroom_id = classrooms.id
                 AND conceptual_exams.discarded_at IS NULL
                 AND conceptual_exams.step_number = school_calendar_classroom_steps.step_number
                 AND EXTRACT(YEAR FROM conceptual_exams.recorded_at) = $1
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
                 AND EXTRACT(YEAR FROM descriptive_exams.recorded_at) = $1
             ) AS td_descriptive_exams,
      LATERAL (SELECT COUNT(1) AS count
             FROM classrooms
             JOIN daily_frequencies
               ON daily_frequencies.classroom_id = classrooms.id,
                  step_by_classroom(classrooms.id, daily_frequencies.frequency_date) AS step
            WHERE classrooms.unity_id = unities.id
              AND step.step_number = school_calendar_classroom_steps.step_number
              AND EXTRACT(YEAR FROM daily_frequencies.frequency_date) = $1
          ) AS td_daily_frequencies,
      LATERAL (SELECT COUNT(1) AS count
                 FROM teaching_plans
                WHERE teaching_plans.unity_id = unities.id
                  AND school_calendar_classroom_steps.step_number = (
                      CASE
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['first_bimester', 'first_bimester_eja', 'first_trimester', 'first_semester']) THEN 1
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['second_bimester', 'second_bimester_eja', 'second_trimester', 'second_semester']) THEN 2
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['third_bimester', 'third_trimester']) THEN 3
                        WHEN COALESCE(teaching_plans.school_term, '') = ANY(ARRAY['fourth_bimester']) THEN 4
                      END
                  )
                  AND teaching_plans.year = $1
          ) AS td_teaching_plans,
      LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN transfer_notes
                   ON transfer_notes.classroom_id = classrooms.id,
                      step_by_classroom(classrooms.id, transfer_notes.recorded_at) AS step
                WHERE classrooms.unity_id = unities.id
                  AND step.step_number = school_calendar_classroom_steps.step_number
                  AND EXTRACT(YEAR FROM transfer_notes.recorded_at) = $1
              ) AS td_transfer_notes,
      LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN complementary_exams
                   ON complementary_exams.classroom_id = classrooms.id
                WHERE classrooms.unity_id = unities.id
                  AND complementary_exams.step_number = school_calendar_classroom_steps.step_number
                  AND EXTRACT(YEAR FROM complementary_exams.recorded_at) = $1
        ) AS td_complementary_exams,
      LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN avaliations
                   ON avaliations.classroom_id = classrooms.id
                 JOIN avaliation_recovery_diary_records
                   ON avaliation_recovery_diary_records.avaliation_id = avaliations.id,
                      step_by_classroom(classrooms.id, avaliations.test_date) AS step
                WHERE classrooms.unity_id = unities.id
                  AND step.step_number = school_calendar_classroom_steps.step_number
                  AND EXTRACT(YEAR FROM avaliations.test_date) = $1
              ) AS td_avaliations_recovery_diary_records,
      LATERAL (SELECT COUNT(1) AS count
                 FROM recovery_diary_records
                 JOIN school_term_recovery_diary_records
                   ON school_term_recovery_diary_records.recovery_diary_record_id = recovery_diary_records.id
                WHERE school_term_recovery_diary_records.step_number = school_calendar_classroom_steps.step_number
                  AND EXTRACT(YEAR FROM school_term_recovery_diary_records.recorded_at) = $1
           ) AS td_school_term_recovery_diary_record
       WHERE school_calendars.year = $1
    ORDER BY unity_name, kind, classroom, step
    SQL
  end

  private

  attr_accessor :unity, :year
end
