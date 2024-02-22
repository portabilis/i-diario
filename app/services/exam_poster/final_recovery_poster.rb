module ExamPoster
  class FinalRecoveryPoster < Base
    private

    def generate_requests
      params = build_params
      params.each do |classroom_id, classroom_score|
        classroom_score.each do |student_id, student_score|
          student_score.each do |discipline_id, discipline_score|
            requests << {
              info: {
                student: student_id,
                discipline: discipline_id
              },
              request: {
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

    def build_params
      params = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      final_recovery_diary_records = fetch_final_recovery_diary_records

      if final_recovery_diary_records.empty?
        @warning_messages << 'Não foi possível encontrar nenhuma recuperação final lançada.'
      end

      final_recovery_diary_records.each do |final_recovery_diary_record|
        classroom = final_recovery_diary_record.recovery_diary_record.classroom

        if final_recovery_diary_record.recovery_diary_record.students.any? { |student| student.score.blank? }
          @warning_messages << "Não foi possível enviar as recuperações finais da turma #{classroom} pois existem alunos sem nota."
        end

        classroom_api_code = classroom.api_code
        discipline_api_code = final_recovery_diary_record.recovery_diary_record.discipline.api_code
        score_rounder = ScoreRounder.new(
          classroom,
          RoundedAvaliations::FINAL_RECOVERY,
          get_step(classroom)
        )

        final_recovery_diary_record.recovery_diary_record.students.each do |recovery_diary_record_student|
          next unless not_posted?({ classroom: classroom,
                                    discipline: recovery_diary_record_student.recovery_diary_record.discipline,
                                    student: recovery_diary_record_student.student })[:final_recovery]

          value = score_rounder.round(recovery_diary_record_student.score)

          params[classroom_api_code][recovery_diary_record_student.student.api_code][discipline_api_code]['nota'] = value
        end
      end

      params
    end

    def fetch_final_recovery_diary_records
      final_recovery_diary_records = []

      teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom_step = get_step(teacher_discipline_classroom.classroom)

        exempted_discipline_ids =
          ExemptedDisciplinesInStep.discipline_ids(
            teacher_discipline_classroom.classroom_id,
            classroom_step.to_number
          )

        next if exempted_discipline_ids.include?(teacher_discipline_classroom.discipline_id)

        final_recovery_diary_record =
          FinalRecoveryDiaryRecord.by_school_calendar_id(classroom_step.school_calendar_id)
                                  .by_classroom_id(teacher_discipline_classroom.classroom.id)
                                  .by_discipline_id(teacher_discipline_classroom.discipline_id)
                                  .first

        final_recovery_diary_records << final_recovery_diary_record if final_recovery_diary_record.present?
      end

      final_recovery_diary_records
    end

    def teacher_discipline_classrooms
      teacher.teacher_discipline_classrooms.select do |teacher_discipline_classroom|
        can_post?(teacher_discipline_classroom.classroom) &&
          valid_score_type?(teacher_discipline_classroom.classroom)
      end
    end

    def valid_score_type?(classroom)
      classroom.classrooms_grades.any? { |classroom_grade|
        [ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT].include?(classroom_grade.exam_rule.score_type)
      }
    end
  end
end
