module ExamPoster
  class ConceptualExamPoster < Base

    private

    def generate_requests
      post_conceptual_exams.each do |classroom_id, conceptual_exam_classroom|
        conceptual_exam_classroom.each do |student_id, conceptual_exam_student|
          conceptual_exam_student.each do |discipline_id, conceptual_exam_discipline|
            self.requests << {
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
          end
        end
      end
    end

    private

    def post_conceptual_exams
      params = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

      classrooms_ids = teacher.classrooms.uniq
      classrooms_ids.each do |classroom|
        next unless step_exists_for_classroom?(classroom)

        if classroom.calendar
          conceptual_exams = ConceptualExam.by_classroom(classroom)
                                           .by_unity(@post_data.step.school_calendar.unity)
                                           .by_school_calendar_classroom_step(get_step(classroom))
        else
          conceptual_exams = ConceptualExam.by_classroom(classroom)
                                           .by_unity(@post_data.step.school_calendar.unity)
                                           .by_school_calendar_step(get_step(classroom))
        end

        conceptual_exams.each do |conceptual_exam|
          conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
            if conceptual_exam_value.value.nil? || conceptual_exam_value.value.blank?
              student_name = conceptual_exam.student.name
              classroom_description = conceptual_exam.classroom.description
              discipline_description = conceptual_exam_value.discipline.description
              @warning_messages << "O aluno #{student_name} não possui nota lançada no diário de notas conceituais na turma #{classroom_description} disciplina: #{discipline_description}"
              next
            end
            classroom_api_code = conceptual_exam.classroom.api_code
            student_api_code = conceptual_exam.student.api_code
            discipline_api_code = conceptual_exam_value.discipline.api_code
            params[classroom_api_code][student_api_code][discipline_api_code]["nota"] = conceptual_exam_value.value
          end
        end
      end
      params
    end
  end
end
