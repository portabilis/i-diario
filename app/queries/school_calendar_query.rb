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
             CASE WHEN td_daily_frequencies.frequencies THEN 'sim' ELSE 'não' END AS frequencias_lancadas,
             CASE WHEN td_teaching_plans.plans THEN 'sim' ELSE 'não' END AS planos_de_ensino_criados,
             CASE WHEN td_yearly_teaching_plans.plans THEN 'sim' ELSE 'não' END AS planos_de_ensino_anual,
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = date_part('year', CURRENT_DATE)
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = date_part('year', CURRENT_DATE)
             ) AS td_daily_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN conceptual_exams
                  ON conceptual_exams.classroom_id = classrooms.id
                 AND conceptual_exams.discarded_at IS NULL
               WHERE classrooms.unity_id = unities.id
                 AND conceptual_exams.step_number = school_calendar_steps.step_number
                 AND EXTRACT(YEAR FROM conceptual_exams.recorded_at) = date_part('year', CURRENT_DATE)
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
                 AND EXTRACT(YEAR FROM descriptive_exams.recorded_at) = date_part('year', CURRENT_DATE)
             ) AS td_descriptive_exams,
     LATERAL (SELECT EXISTS (
                SELECT 1
                  FROM classrooms
                  JOIN daily_frequencies
                    ON daily_frequencies.classroom_id = classrooms.id,
                       step_by_classroom(classrooms.id, daily_frequencies.frequency_date) AS step
                 WHERE classrooms.unity_id = unities.id
                   AND step.step_number = school_calendar_steps.step_number
                   AND EXTRACT(YEAR FROM daily_frequencies.frequency_date) = date_part('year', CURRENT_DATE)) AS frequencies
             ) AS td_daily_frequencies,
     LATERAL (SELECT EXISTS (
                SELECT 1
                  FROM teaching_plans
                  JOIN school_term_types ON teaching_plans.school_term_type_id = school_term_types.id
                  JOIN school_term_type_steps ON school_term_types.id = school_term_type_steps.school_term_type_id
                 WHERE teaching_plans.unity_id = unities.id
                   AND teaching_plans.school_term_type_id <> 1
                   AND school_calendar_steps.step_number = school_term_type_steps.step_number
                   AND teaching_plans.year = date_part('year', CURRENT_DATE)) AS plans
             ) AS td_teaching_plans,
     LATERAL (SELECT EXISTS (
                SELECT 1
                  FROM teaching_plans
                 WHERE teaching_plans.unity_id = unities.id
                   AND teaching_plans.school_term_type_id = #{yearly_term_type_id}
                   AND teaching_plans.year = date_part('year', CURRENT_DATE)) AS plans
             ) AS td_yearly_teaching_plans,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN transfer_notes
                  ON transfer_notes.classroom_id = classrooms.id,
                     step_by_classroom(classrooms.id, transfer_notes.recorded_at) AS step
               WHERE classrooms.unity_id = unities.id
                 AND step.step_number = school_calendar_steps.step_number
                 AND EXTRACT(YEAR FROM transfer_notes.recorded_at) = date_part('year', CURRENT_DATE)
             ) AS td_transfer_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM classrooms
                JOIN complementary_exams
                  ON complementary_exams.classroom_id = classrooms.id
               WHERE classrooms.unity_id = unities.id
                 AND complementary_exams.step_number = school_calendar_steps.step_number
                 AND EXTRACT(YEAR FROM complementary_exams.recorded_at) = date_part('year', CURRENT_DATE)
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = date_part('year', CURRENT_DATE)
             ) AS td_avaliations_recovery_diary_records,
     LATERAL (SELECT COUNT(1) AS count
                FROM recovery_diary_records
                JOIN school_term_recovery_diary_records
                  ON school_term_recovery_diary_records.recovery_diary_record_id = recovery_diary_records.id
               WHERE school_term_recovery_diary_records.step_number = school_calendar_steps.step_number
                 AND recovery_diary_records.unity_id = unities.id
                 AND EXTRACT(YEAR FROM school_term_recovery_diary_records.recorded_at) = date_part('year', CURRENT_DATE)
             ) AS td_school_term_recovery_diary_record
       WHERE school_calendars.year = date_part('year', CURRENT_DATE)
       UNION ALL
      SELECT unities.name AS unity_name,
             'Turma' AS kind,
             school_calendar_classroom_steps.step_number AS step,
             school_calendar_classrooms.step_type_description AS step_name,
             classrooms.description AS classroom,
             school_calendar_classroom_steps.start_at AS start_at,
             school_calendar_classroom_steps.end_at AS end_at,
             school_calendar_classroom_steps.start_date_for_posting AS start_date_for_posting,
             school_calendar_classroom_steps.end_date_for_posting AS end_date_for_posting,
             td_avaliations.count AS avaliacoes_criadas,
             td_daily_notes.count AS avaliacoes_lancadas,
             td_conceptual_exams.count AS avaliacoes_conceituais_lancadas,
             td_descriptive_exams.count AS avaliacoes_descritivas_lancadas,
             CASE WHEN td_daily_frequencies.frequencies THEN 'sim' ELSE 'não' END AS frequencias_lancadas,
             CASE WHEN td_teaching_plans.plans THEN 'sim' ELSE 'não' END AS planos_de_ensino_criados,
             CASE WHEN td_yearly_teaching_plans.plans THEN 'sim' ELSE 'não' END AS planos_de_ensino_anual,
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
                 AND EXTRACT(YEAR FROM avaliations.test_date) = date_part('year', CURRENT_DATE)
             ) AS td_avaliations,
     LATERAL (SELECT COUNT(1) AS count
                FROM avaliations
                JOIN daily_notes
                  ON daily_notes.avaliation_id = avaliations.id,
                     step_by_classroom(classrooms.id, avaliations.test_date) AS step
               WHERE avaliations.classroom_id = classrooms.id
                 AND step.step_number = school_calendar_classroom_steps.step_number
                 AND EXTRACT(YEAR FROM avaliations.test_date) = date_part('year', CURRENT_DATE)
             ) AS td_daily_notes,
     LATERAL (SELECT COUNT(1) AS count
                FROM conceptual_exams
               WHERE conceptual_exams.classroom_id = classrooms.id
                 AND conceptual_exams.discarded_at IS NULL
                 AND conceptual_exams.step_number = school_calendar_classroom_steps.step_number
                 AND EXTRACT(YEAR FROM conceptual_exams.recorded_at) = date_part('year', CURRENT_DATE)
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
                 AND EXTRACT(YEAR FROM descriptive_exams.recorded_at) = date_part('year', CURRENT_DATE)
             ) AS td_descriptive_exams,
     LATERAL (SELECT EXISTS (
                SELECT 1
                  FROM classrooms
                  JOIN daily_frequencies
                    ON daily_frequencies.classroom_id = classrooms.id,
                       step_by_classroom(classrooms.id, daily_frequencies.frequency_date) AS step
                 WHERE classrooms.unity_id = unities.id
                   AND step.step_number = school_calendar_classroom_steps.step_number
                   AND EXTRACT(YEAR FROM daily_frequencies.frequency_date) = date_part('year', CURRENT_DATE)) AS frequencies
             ) AS td_daily_frequencies,
     LATERAL (SELECT EXISTS (
                SELECT 1
                  FROM teaching_plans
                  JOIN school_term_types ON teaching_plans.school_term_type_id = school_term_types.id
                  JOIN school_term_type_steps ON school_term_types.id = school_term_type_steps.school_term_type_id
                 WHERE teaching_plans.unity_id = unities.id
                   AND teaching_plans.school_term_type_id <> 1
                   AND teaching_plans.grade_id = (
                     SELECT grade_id
                       FROM classrooms
                      WHERE id = school_calendar_classrooms.classroom_id
                      LIMIT 1
                   )
                   AND school_calendar_classroom_steps.step_number = school_term_type_steps.step_number
                   AND teaching_plans.year = date_part('year', CURRENT_DATE)) AS plans
             ) AS td_teaching_plans,
     LATERAL (SELECT EXISTS (
                SELECT 1
                  FROM teaching_plans
                 WHERE teaching_plans.unity_id = unities.id
                   AND teaching_plans.school_term_type_id = #{yearly_term_type_id}
                   AND teaching_plans.year = date_part('year', CURRENT_DATE)) AS plans
             ) AS td_yearly_teaching_plans,
     LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN transfer_notes
                   ON transfer_notes.classroom_id = classrooms.id,
                      step_by_classroom(classrooms.id, transfer_notes.recorded_at) AS step
                WHERE classrooms.unity_id = unities.id
                  AND step.step_number = school_calendar_classroom_steps.step_number
                  AND EXTRACT(YEAR FROM transfer_notes.recorded_at) = date_part('year', CURRENT_DATE)
             ) AS td_transfer_notes,
     LATERAL (SELECT COUNT(1) AS count
                 FROM classrooms
                 JOIN complementary_exams
                   ON complementary_exams.classroom_id = classrooms.id
                WHERE classrooms.unity_id = unities.id
                  AND complementary_exams.step_number = school_calendar_classroom_steps.step_number
                  AND EXTRACT(YEAR FROM complementary_exams.recorded_at) = date_part('year', CURRENT_DATE)
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
                  AND EXTRACT(YEAR FROM avaliations.test_date) = date_part('year', CURRENT_DATE)
             ) AS td_avaliations_recovery_diary_records,
     LATERAL (SELECT COUNT(1) AS count
                 FROM recovery_diary_records
                 JOIN school_term_recovery_diary_records
                   ON school_term_recovery_diary_records.recovery_diary_record_id = recovery_diary_records.id
                WHERE school_term_recovery_diary_records.step_number = school_calendar_classroom_steps.step_number
                  AND recovery_diary_records.unity_id = unities.id
                  AND EXTRACT(YEAR FROM school_term_recovery_diary_records.recorded_at) = date_part('year', CURRENT_DATE)
             ) AS td_school_term_recovery_diary_record
       WHERE school_calendars.year = date_part('year', CURRENT_DATE)
    ORDER BY unity_name, kind, classroom, step
    SQL
  end

  private

  attr_accessor :unity, :year

  def self.yearly_term_type_id
    @yearly_term_type_id ||= SchoolTermType.find_by(description: 'Anual').id
  end

  private_class_method :yearly_term_type_id
end
