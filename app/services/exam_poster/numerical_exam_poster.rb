module ExamPoster
  class NumericalExamPoster < Base

    private

    def generate_requests
      post_by_classrooms.each do |classroom_id, classroom_score|
        classroom_score.each do |student_id, student_score|
          student_score.each do |discipline_id, discipline_score|
            self.requests << {
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
          end
        end
      end
    end

    def post_by_classrooms
      scores = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      classroom_ids = teacher.teacher_discipline_classrooms.pluck(:classroom_id).uniq.compact

      classroom_ids.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms
                                               .where(classroom_id: classroom)
                                               .where(score_type: [DisciplineScoreTypes::NUMERIC, nil])

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          classroom = teacher_discipline_classroom.classroom
          discipline = teacher_discipline_classroom.discipline

          next if !same_unity(classroom.unity_id)
          next unless step_exists_for_classroom?(classroom)

          teacher_score_fetcher = TeacherScoresFetcher.new(teacher, classroom, discipline, get_step(classroom))
          teacher_score_fetcher.fetch!

          student_scores = teacher_score_fetcher.scores

          student_scores.each do |student_score|
            next if exempted_discipline(classroom.id, discipline.id, student_score.id)
            next if !correct_score_type(student_score.uses_differentiated_exam_rule, classroom.exam_rule)

            school_term_recovery = fetch_school_term_recovery_score(classroom, discipline, student_score.id)
            value = StudentAverageCalculator.new(student_score).calculate(classroom, discipline, @post_data.step)
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['nota'] = value
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['recuperacao'] = ScoreRounder.new(classroom).round(school_term_recovery) if school_term_recovery
          end
          @warning_messages += teacher_score_fetcher.warning_messages if teacher_score_fetcher.has_warnings?
        end
      end
      return scores
    end

    def same_unity(unity_id)
      unity_id == @post_data.step.school_calendar.unity_id
    end

    def correct_score_type(differentiated, exam_rule)
      exam_rule = (exam_rule.differentiated_exam_rule || exam_rule) if differentiated
      score_types = [ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT]
      score_types.include? exam_rule.score_type
    end

    def fetch_school_term_recovery_score(classroom, discipline, student)
      school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord
        .by_classroom_id(classroom)
        .by_discipline_id(discipline)
        .by_step_id(classroom, get_step(classroom).id)
        .first

      return unless school_term_recovery_diary_record

      student_recovery = RecoveryDiaryRecordStudent
        .by_student_id(student)
        .by_recovery_diary_record_id(school_term_recovery_diary_record.recovery_diary_record_id)
        .first

      score = student_recovery.try(:score)

      if score.present?
        score = ComplementaryExamCalculator.new(AffectedScoreTypes::STEP_RECOVERY_SCORE, student, discipline.id, classroom.id, @post_data.step).calculate(score)
      end

      score
    end

    def exempted_discipline(classroom_id, discipline_id, student_id)
      student_enrollment_classroom = StudentEnrollmentClassroom.by_classroom(classroom_id)
                                                               .by_student(student_id)
                                                               .active
                                                               .first

      if student_enrollment_classroom.present?
        return student_enrollment_classroom.student_enrollment
                                           .exempted_disciplines
                                           .by_discipline(discipline_id)
                                           .by_step_number(@post_data.step.to_number)
                                           .any?
      end

      false
    end
  end
end
