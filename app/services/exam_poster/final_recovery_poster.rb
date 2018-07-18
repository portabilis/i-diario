module ExamPoster
  class FinalRecoveryPoster < Base

    private

    def generate_requests
      params = build_params
      params.each do |classroom_id, classroom_score|
        classroom_score.each do |student_id, student_score|
          student_score.each do |discipline_id, discipline_score|
            self.requests << {
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

    private

    def build_params
      params = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      final_recovery_diary_records = fetch_final_recovery_diary_records

      if final_recovery_diary_records.empty?
        @warning_messages << "Não foi possível encontrar nenhuma recuperação final lançada."
      end

      final_recovery_diary_records.each do |final_recovery_diary_record|
        if final_recovery_diary_record.recovery_diary_record.students.any? { |student| student.score.blank? }
          @warning_messages << "Não foi possível enviar as recuperações finais da turma #{final_recovery_diary_record.recovery_diary_record.classroom} pois existem alunos sem nota."
        end

        classroom_exam_rule = final_recovery_diary_record.recovery_diary_record.classroom.exam_rule
        classroom_api_code = final_recovery_diary_record.recovery_diary_record.classroom.api_code
        discipline_api_code = final_recovery_diary_record.recovery_diary_record.discipline.api_code

        final_recovery_diary_record.recovery_diary_record.students.each do |student|
          params[classroom_api_code][student.student.api_code][discipline_api_code]['nota'] = ScoreRounder.new(final_recovery_diary_record.recovery_diary_record.classroom).round(student.score)
        end
      end

      params
    end

    def fetch_final_recovery_diary_records
      final_recovery_diary_records = []

      teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        final_recovery_diary_record = FinalRecoveryDiaryRecord.by_school_calendar_id(@post_data.step.school_calendar_id)
          .by_classroom_id(teacher_discipline_classroom.classroom.id)
          .by_discipline_id(teacher_discipline_classroom.discipline.id)
          .first

        final_recovery_diary_records << final_recovery_diary_record unless final_recovery_diary_record.blank?
      end

      final_recovery_diary_records
    end

    def teacher_discipline_classrooms
      @post_data.author.current_teacher.teacher_discipline_classrooms.select do |teacher_discipline_classroom|
        valid_unity?(teacher_discipline_classroom.classroom.unity_id) && valid_score_type?(teacher_discipline_classroom.classroom.exam_rule.score_type)
      end
    end

    def valid_unity?(unity_id)
      unity_id == @post_data.step.school_calendar.unity_id
    end

    def valid_score_type?(score_type)
      score_type == ScoreTypes::NUMERIC || score_type == ScoreTypes::NUMERIC_AND_CONCEPT
    end
  end
end
