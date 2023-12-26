module ExamPoster
  class ConceptualExamPoster < Base
    private

    def generate_requests
      post_conceptual_exams.each do |classroom_id, conceptual_exam_classroom|
        conceptual_exam_classroom.each do |student_id, conceptual_exam_student|
          conceptual_exam_student.each do |discipline_id, conceptual_exam_discipline|
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
                      discipline_id => conceptual_exam_discipline
                    }
                  }
                }
              }
            }
          end
        end
      end
    end

    def post_conceptual_exams
      params = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      classrooms.each do |classroom|
        next unless can_post?(classroom)

        conceptual_exam_ids = ConceptualExam.joins(:student)
                                            .by_classroom(classroom)
                                            .by_unity(get_step(classroom).school_calendar.unity)
                                            .by_step_id(classroom, get_step(classroom).id)
                                            .pluck(:id)
        exempted_discipline_ids =
          ExemptedDisciplinesInStep.discipline_ids(classroom.id, get_step(classroom).to_number)
        conceptual_exam_values = ConceptualExamValue.active
                                                    .includes(:conceptual_exam, :discipline)
                                                    .where(conceptual_exam_id: conceptual_exam_ids)
                                                    .where.not(discipline_id: exempted_discipline_ids)
                                                    .where(discipline_id: discipline_ids)
                                                    .distinct

        conceptual_exam_values.each do |conceptual_exam_value|
          conceptual_exam = conceptual_exam_value.conceptual_exam

          next unless not_posted?({ classroom: classroom, student: conceptual_exam.student, discipline: conceptual_exam_value.discipline })[:conceptual_exam]

          if conceptual_exam_value.value.blank?
            student_name = conceptual_exam.student.name
            classroom_description = conceptual_exam.classroom.description
            discipline_description = conceptual_exam_value.discipline.description
            @warning_messages << "O aluno #{student_name} não possui nota lançada no diário de notas conceituais na turma #{classroom_description} disciplina: #{discipline_description}"
            next
          end

          classroom_api_code = conceptual_exam.classroom.api_code
          student_api_code = conceptual_exam.student.api_code
          discipline_api_code = conceptual_exam_value.discipline.api_code

          params[classroom_api_code][student_api_code][discipline_api_code]['nota'] = conceptual_exam_value.value
        end
      end

      params
    end
  end
end
