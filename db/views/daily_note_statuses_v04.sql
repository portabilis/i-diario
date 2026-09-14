-- Status do diário de avaliação numérica, calculado em tempo de consulta (a view não é materializada).
-- 1. `incomplete` quando existe linha de aluno sem nota que conta como pendente: linha ativa e não descartada,
--    sem nota de transferência, sem dispensa da avaliação, aluno enturmado na data da avaliação e fora de busca ativa.
-- 2. `complete` quando o diário tem linhas e nenhuma delas está pendente.
-- 3. Diário sem nenhuma linha de aluno não descartada, de turma com ano letivo a partir de 2026, fica
--    `incomplete` quando existe aluno que a lista do diário mostraria como pendente: enturmado numa série da avaliação
--    na data, matrícula ativa, tipo de nota numérico pelo mesmo critério de StudentEnrollmentClassroom.by_score_type_query
--    (inclusive regra diferenciada), fora de busca ativa e sem dispensa da avaliação. Turmas de anos letivos anteriores
--    sem linha ficam `complete`.
-- A dispensa da disciplina por etapa não entra na regra 3, porque o número da etapa é resolvido em Ruby (StepsFetcher).
SELECT outer_daily_notes.id AS daily_note_id,
  CASE
    WHEN (
      EXISTS (
        SELECT daily_notes.id
          FROM daily_notes
          JOIN daily_note_students ON (
            daily_notes.id = daily_note_students.daily_note_id
          )
          JOIN avaliations ON (
            daily_notes.avaliation_id = avaliations.id
          )
          WHERE daily_note_students.note IS NULL
            AND daily_note_students.active = true
            AND daily_note_students.transfer_note_id IS NULL
            AND daily_note_students.discarded_at IS NULL
            AND NOT (
              EXISTS (
                SELECT 1
                  FROM avaliation_exemptions
                WHERE avaliation_exemptions.avaliation_id = daily_notes.avaliation_id
                  AND avaliation_exemptions.student_id = daily_note_students.student_id
              )
            )
            AND (
              EXISTS (
                SELECT 1
                  FROM student_enrollment_classrooms
                  JOIN classrooms_grades ON (
                  student_enrollment_classrooms.classrooms_grade_id = classrooms_grades.id
                  )
                  AND classrooms_grades.classroom_id = avaliations.classroom_id
                  JOIN student_enrollments ON (
                    student_enrollment_classrooms.student_enrollment_id = student_enrollments.id
                  )
                  AND student_enrollments.student_id = daily_note_students.student_id
                  AND (
                    student_enrollment_classrooms.left_at = ''
                    OR (
                      avaliations.test_date::date < student_enrollment_classrooms.left_at::date
                      AND avaliations.test_date::date >= student_enrollment_classrooms.joined_at::date
                    )
                  )
                  AND student_enrollments.active = 1
                  AND NOT (
                    EXISTS (
                      SELECT 1
                        FROM active_searches
                      WHERE active_searches.student_enrollment_id = student_enrollments.id
                        AND active_searches.discarded_at IS NULL
                        AND avaliations.test_date::date >= active_searches.start_date
                        AND (
                          active_searches.end_date IS NULL
                          OR avaliations.test_date::date <= active_searches.end_date
                        )
                    )
                  )
              )
            )
          AND daily_notes.id = outer_daily_notes.id
      )
    )
    THEN
      'incomplete'::text
    WHEN EXISTS (
        SELECT 1
          FROM daily_note_students
         WHERE daily_note_students.daily_note_id = outer_daily_notes.id
           AND daily_note_students.discarded_at IS NULL
      )
    THEN
      'complete'::text
    WHEN EXISTS (
        SELECT 1
          FROM avaliations
          JOIN classrooms ON (
            classrooms.id = avaliations.classroom_id
            AND classrooms.year >= 2026
          )
          JOIN avaliations_grades ON (
            avaliations_grades.avaliation_id = avaliations.id
          )
          JOIN classrooms_grades ON (
            classrooms_grades.classroom_id = avaliations.classroom_id
            AND classrooms_grades.grade_id = avaliations_grades.grade_id
            AND classrooms_grades.discarded_at IS NULL
          )
          LEFT JOIN exam_rules ON (
            exam_rules.id = classrooms_grades.exam_rule_id
          )
          JOIN student_enrollment_classrooms ON (
            student_enrollment_classrooms.classrooms_grade_id = classrooms_grades.id
            AND student_enrollment_classrooms.discarded_at IS NULL
          )
          JOIN student_enrollments ON (
            student_enrollments.id = student_enrollment_classrooms.student_enrollment_id
            AND student_enrollments.active = 1
            AND student_enrollments.discarded_at IS NULL
          )
          JOIN students ON (
            students.id = student_enrollments.student_id
          )
         WHERE avaliations.id = outer_daily_notes.avaliation_id
           AND avaliations.test_date >= NULLIF(student_enrollment_classrooms.joined_at, '')::date
           AND (
             COALESCE(student_enrollment_classrooms.left_at, '') = ''
             OR avaliations.test_date < NULLIF(student_enrollment_classrooms.left_at, '')::date
           )
           AND (
             NOT EXISTS (
               SELECT 1
                 FROM classrooms_grades numeric_grades
                 JOIN exam_rules numeric_rules ON numeric_rules.id = numeric_grades.exam_rule_id
                WHERE numeric_grades.classroom_id = avaliations.classroom_id
                  AND numeric_grades.discarded_at IS NULL
                  AND numeric_rules.score_type = '1'
             )
             OR (
               exam_rules.score_type = '1'
               AND (
                 NOT students.uses_differentiated_exam_rule
                 OR NOT EXISTS (
                   SELECT 1
                     FROM classrooms_grades numeric_grades
                     JOIN exam_rules numeric_rules ON numeric_rules.id = numeric_grades.exam_rule_id
                    WHERE numeric_grades.classroom_id = avaliations.classroom_id
                      AND numeric_grades.discarded_at IS NULL
                      AND numeric_rules.score_type = '1'
                      AND numeric_rules.differentiated_exam_rule_id IS NOT NULL
                 )
                 OR EXISTS (
                   SELECT 1
                     FROM classrooms_grades numeric_grades
                     JOIN exam_rules numeric_rules ON numeric_rules.id = numeric_grades.exam_rule_id
                     JOIN exam_rules differentiated_rules ON differentiated_rules.id = numeric_rules.differentiated_exam_rule_id
                    WHERE numeric_grades.classroom_id = avaliations.classroom_id
                      AND numeric_grades.discarded_at IS NULL
                      AND numeric_rules.score_type = '1'
                      AND differentiated_rules.score_type IN ('1', '3')
                 )
               )
             )
           )
           AND NOT EXISTS (
             SELECT 1
               FROM active_searches
              WHERE active_searches.student_enrollment_id = student_enrollments.id
                AND active_searches.discarded_at IS NULL
                AND avaliations.test_date >= active_searches.start_date
                AND (
                  active_searches.end_date IS NULL
                  OR avaliations.test_date <= active_searches.end_date
                )
           )
           AND NOT EXISTS (
             SELECT 1
               FROM avaliation_exemptions
              WHERE avaliation_exemptions.avaliation_id = avaliations.id
                AND avaliation_exemptions.student_id = students.id
                AND avaliation_exemptions.discarded_at IS NULL
           )
      )
    THEN
      'incomplete'::text
    ELSE
      'complete'::text
  END AS status
FROM daily_notes outer_daily_notes;
