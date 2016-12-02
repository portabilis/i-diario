module ExamPoster
  class ConceptualExamPoster < Base
    def self.post!(post_data)
      new(post_data).post!
    end

    def post!
      post_conceptual_exams.each do |classroom_id, conceptual_exam_classroom|
        conceptual_exam_classroom.each do |student_id, conceptual_exam_student|
          conceptual_exam_student.each do |discipline_id, conceptual_exam_discipline|
            api.send_post( notas: { classroom_id => { student_id => { discipline_id => conceptual_exam_discipline } } }, etapa: @post_data.step.to_number, resource: 'notas' )
          end
        end
      end
      return { warning_messages: @warning_messages }
    end

    private

    def api
      IeducarApi::PostExams.new(@post_data.to_api)
    end

    def post_conceptual_exams
      params = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

      if has_classroom_steps
        conceptual_exams = ConceptualExam.by_teacher(@post_data.author.current_teacher)
          .by_unity(@post_data.step.school_calendar.unity)
          .by_school_calendar_classroom_step(@post_data.step)
      else
        conceptual_exams = ConceptualExam.by_teacher(@post_data.author.current_teacher)
          .by_unity(@post_data.step.school_calendar.unity)
          .by_school_calendar_step(@post_data.step)
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

      params
    end

    def has_classroom_steps
      SchoolCalendarClassroomStep.find(@post_data.step)
    end
  end
end
