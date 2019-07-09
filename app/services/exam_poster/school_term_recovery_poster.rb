module ExamPoster
  class SchoolTermRecoveryPoster < Base
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
                resource: 'recuperacoes',
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

      classroom_ids = teacher.teacher_discipline_classrooms.pluck(:classroom_id).uniq.compact

      classroom_ids.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          classroom = teacher_discipline_classroom.classroom
          discipline = teacher_discipline_classroom.discipline
          score_rounder = ScoreRounder.new(classroom, RoundedAvaliations::SCHOOL_TERM_RECOVERY)

          next unless can_post?(classroom)
          next unless correct_score_type(classroom.exam_rule.score_type)

          exempted_discipline_ids =
            ExemptedDisciplinesInStep.discipline_ids(classroom.id, get_step(classroom).to_number)

          next if exempted_discipline_ids.include?(discipline.id)

          teacher_score_fetcher = TeacherScoresFetcher.new(teacher, classroom, discipline, get_step(classroom))
          teacher_score_fetcher.fetch!

          student_scores = teacher_score_fetcher.scores

          student_scores.each do |student_score|
            next if exempted_discipline(classroom, discipline.id, student_score.id)

            school_term_recovery = fetch_school_term_recovery_score(classroom, discipline, student_score.id)
            next unless school_term_recovery

            value = StudentAverageCalculator.new(student_score)
                                            .calculate(classroom, discipline, get_step(classroom))
            recovery_value = score_rounder.round(school_term_recovery)
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['nota'] = value
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['recuperacao'] = recovery_value
          end

          students_only_with_recovery_fetcher = StudentOnlyWithRecoveryFetcher.new(
            teacher,
            classroom,
            discipline,
            get_step(classroom)
          )
          students_only_with_recovery_fetcher.fetch!
          students_without_daily_notes = students_only_with_recovery_fetcher.recoveries || []

          students_without_daily_notes.each do |student_recovery|
            student = student_recovery.student

            next if exempted_discipline(classroom, discipline.id, student.id)

            score = student_recovery.try(:score)

            next if score.blank?

            value = score_rounder.round(score)
            scores[classroom.api_code][student.api_code][discipline.api_code]['recuperacao'] = value
          end
        end
      end

      scores
    end

    def correct_score_type(score_type)
      score_type == ScoreTypes::NUMERIC
    end

    def fetch_school_term_recovery_score(classroom, discipline, student)
      school_term_recovery_diary_record = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom)
                                                                       .by_discipline_id(discipline)
                                                                       .by_step_id(
                                                                         classroom,
                                                                         get_step(classroom).id
                                                                       )
                                                                       .first

      return unless school_term_recovery_diary_record

      student_recovery = RecoveryDiaryRecordStudent.by_student_id(student)
                                                   .by_recovery_diary_record_id(
                                                     school_term_recovery_diary_record.recovery_diary_record_id
                                                   )
                                                   .first

      student_recovery.try(:score)
    end

    def exempted_discipline(classroom, discipline_id, student_id)
      student_enrollment_classroom = StudentEnrollmentClassroom.by_classroom(classroom.id)
                                                               .by_student(student_id)
                                                               .active
                                                               .first

      if student_enrollment_classroom.present?
        return student_enrollment_classroom.student_enrollment
                                           .exempted_disciplines
                                           .by_discipline(discipline_id)
                                           .by_step_number(get_step(classroom).to_number)
                                           .any?
      end

      false
    end
  end
end
