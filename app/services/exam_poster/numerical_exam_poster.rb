module ExamPoster
  class NumericalExamPoster < Base
    private

    def generate_requests
      post_by_classrooms.each do |classroom_id, classroom_score|
        classroom_score.each do |student_id, student_score|
          student_score.each do |discipline_id, discipline_score|
            requests << {
              info: {
                classroom: classroom_id,
                student: student_id,
                discipline: discipline_id
              },
              request: {
                etapa: @post_data.step.to_number,
                resource: 'notas',
                notas: {
                  classroom_id => {
                    student_id => {
                      discipline_id => discipline_score
                    }
                  }
                }
              }
            }
          end
        end
      end
    end

    def post_by_classrooms
      scores = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      teacher_discipline_classrooms = teacher.teacher_discipline_classrooms
                                             .where.not(grade_id: nil)
                                             .by_score_type([ScoreTypes::NUMERIC, nil])
                                             .by_year(@post_data.step.school_calendar.year)
                                             .includes(:classroom, :discipline)
                                             .distinct
                                             .compact

      teacher_discipline_classrooms.each do |tdc|
        classroom = tdc.classroom
        discipline = tdc.discipline
        step = get_step(classroom)
        school_term_recovery_diary_record = school_term_recovery_diary_record(
          classroom, discipline, step.id
        )

        score_rounder = ScoreRounder.new(
          classroom,
          RoundedAvaliations::SCHOOL_TERM_RECOVERY,
          step
        )

        next unless can_post?(classroom)

        teacher_score_fetcher = TeacherScoresFetcher.new(
          teacher,
          classroom,
          discipline,
          step
        )
        teacher_score_fetcher.fetch!

        teacher_recovery_score_fetcher = StudentOnlyWithRecoveryFetcher.new(
          teacher_score_fetcher,
          school_term_recovery_diary_record
        )
        teacher_recovery_score_fetcher.fetch!

        student_scores = teacher_score_fetcher.scores + teacher_recovery_score_fetcher.scores
        exam_rules = fetch_exam_rules(classroom, student_scores)
        exempted_disciplines = exempt_discipline_students(classroom, discipline.id, student_scores, step)
        exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(classroom.id, step.to_number)

        if school_term_recovery_diary_record
          enrolled_on_date = enrolled_on_date?(classroom, school_term_recovery_diary_record, student_scores)
          recovery_diary_record = fecth_recovery_diary_record_students(student_scores, school_term_recovery_diary_record)
        else
          enrolled_on_date = {}
          recovery_diary_record = {}
        end

        student_scores.each do |student_score|
          exam_rule = exam_rules[student_score.id] ? exam_rules[student_score.id][:exam_rule] : nil
          next if exempted_disciplines[student_score.id].present?
          next unless correct_score_type(student_score.uses_differentiated_exam_rule, exam_rule)
          next unless numerical_or_school_term_recovery?(classroom, discipline, student_score) || exist_complementary_exam?(classroom, discipline, student_score, step)

          next if exempted_discipline_ids.include?(discipline.id)

          if (value = StudentAverageCalculator.new(student_score)
                                              .calculate(classroom, discipline, step))
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['nota'] = value
          end

          if enrolled_on_date[student_score.id]
            school_term_recovery = fetch_school_term_recovery_score(
              classroom,
              discipline,
              student_score.id,
              school_term_recovery_diary_record,
              recovery_diary_record[student_score.id],
              step
            )

            next unless school_term_recovery
          end

          if (recovery_value = score_rounder.round(school_term_recovery))
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['recuperacao'] = recovery_value
          end
          @warning_messages += teacher_score_fetcher.warning_messages if teacher_score_fetcher.warnings?
        end
      end
      scores
    end

    def fetch_exam_rules(classroom, students)
      enrollment_classrooms = StudentEnrollmentClassroom
        .includes(student_enrollment: :student, classrooms_grade: :exam_rule)
        .by_student(students)
        .by_classroom(classroom)
        .by_date(Date.current)

      enrollment_classrooms_exam_rules = {}

      enrollment_classrooms.each do |sec|
        student_id = sec.student_enrollment.student_id
        exam_rule = sec.classrooms_grade.exam_rule

        next if enrollment_classrooms_exam_rules.key?(student_id)

        enrollment_classrooms_exam_rules[sec.student_id] = {
          exam_rule: exam_rule
        }
      end

      enrollment_classrooms_exam_rules
    end

    def exist_complementary_exam?(classroom, discipline, student_score, step)
      start_at = step.start_at
      end_at = step.end_at

      complementary_exams = ComplementaryExam.by_classroom_id(classroom)
                                             .by_discipline_id(discipline)
                                             .by_date_range(start_at, end_at)

      ComplementaryExamStudent.by_complementary_exam_id(complementary_exams).by_student_id(student_score)
    end

    def numerical_or_school_term_recovery?(classroom, discipline, student_score)
      numerical_exam = not_posted?({ classroom: classroom, discipline: discipline, student: student_score })[:numerical_exam]
      school_term_recovery = not_posted?({ classroom: classroom, discipline: discipline, student: student_score })[:school_term_recovery]
      numerical_exam || school_term_recovery
    end

    def correct_score_type(differentiated, exam_rule)
      return if exam_rule.nil?

      exam_rule = (exam_rule.differentiated_exam_rule || exam_rule) if differentiated
      score_types = [ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT]
      score_types.include? exam_rule&.score_type
    end

    def fecth_recovery_diary_record_students(students, school_term_recovery_diary_record)
      recovery_diary_record_id = school_term_recovery_diary_record.recovery_diary_record_id

      recovery_diary_records = RecoveryDiaryRecordStudent.by_student_id(students)
                                                         .by_recovery_diary_record_id(recovery_diary_record_id)

      return {} if recovery_diary_records.blank?

      student_recovery_diary_records = {}

      recovery_diary_records.each do |recovery_diary_record|
        student_id = recovery_diary_record.student_id

        next if student_recovery_diary_records.key?(student_id)

        student_recovery_diary_records[recovery_diary_record.student_id] = recovery_diary_record
      end

      student_recovery_diary_records
    end

    def fetch_school_term_recovery_score(classroom,
      discipline,
      student,
      school_term_recovery_diary_record,
      student_recovery,
      step
    )
      return unless school_term_recovery_diary_record

      score = student_recovery.try(:score)

      if score.present?
        score = ComplementaryExamCalculator.new(
          [AffectedScoreTypes::STEP_RECOVERY_SCORE, AffectedScoreTypes::BOTH],
          student,
          discipline.id,
          classroom.id,
          step
        ).calculate(score)
      end

      score
    end

    def enrolled_on_date?(classroom, school_term_recovery_diary_record, students)
      student_enrollment_classrooms = StudentEnrollmentClassroom.includes(student_enrollment: :student)
                                                                .by_classroom(classroom)
                                                                .by_student(students)
                                                                .by_date(school_term_recovery_diary_record.recorded_at)
      return {} if student_enrollment_classrooms.blank?

      enrolled_on_date = {}

      student_enrollment_classrooms.each do |sec|
        enrolled_on_date[sec.student_id] = sec
      end

      enrolled_on_date
    end

    def exempt_discipline_students(classroom, discipline_id, students, step)
      step_number = step.to_number
      student_enrollments = StudentEnrollmentClassroom.includes(student_enrollment: [:student])
                                                      .by_classroom(classroom.id)
                                                      .by_student(students)
                                                      .active
                                                      .map(&:student_enrollment)

      exempt_discipline_students = StudentEnrollmentExemptedDiscipline.includes(student_enrollment: :student).where(
        student_enrollment: student_enrollments,
        discipline_id: discipline_id
      ).by_step_number(step_number)

      return {} if exempt_discipline_students.blank?

      student_exempted_in_disciplines = {}

      exempt_discipline_students.each do |exempt|
        student_id = exempt.student_enrollment.student_id

        next if student_exempted_in_disciplines.key?(student_id)

        student_exempted_in_disciplines[student_id] = exempt
      end

      student_exempted_in_disciplines
    end

    def school_term_recovery_diary_record(classroom, discipline, step)
      SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom)
                                   .by_discipline_id(discipline)
                                   .by_step_id(
                                     classroom,
                                     step
                                   )
                                   .first
    end
  end
end
