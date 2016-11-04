module ExamPoster
  class DescriptiveExamPoster < Base
    def self.post!(post_data)
      new(post_data).post!
    end

    def post!
      post_by_step.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, descriptive_exam|
          api.send_post(pareceres: { classroom_id => { student_id => descriptive_exam } }, etapa: @post_data.school_calendar_step.to_number, resource: 'pareceres-por-etapa-geral')
        end
      end

      post_by_year.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, descriptive_exam|
          api.send_post(pareceres: { classroom_id => { student_id => descriptive_exam } }, resource: 'pareceres-anual-geral')
        end
      end

      post_by_year_and_discipline.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
          student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
            api.send_post(pareceres: { classroom_id => { student_id => { discipline_id => discipline_descriptive_exam } } }, resource: 'pareceres-anual-por-componente')
          end
        end
      end

      post_by_step_and_discipline.each do |classroom_id, classroom_descriptive_exam|
        classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
          student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
            api.send_post(pareceres: { classroom_id => { student_id => { discipline_id => discipline_descriptive_exam } } }, etapa: @post_data.school_calendar_step.to_number, resource: 'pareceres-por-etapa-e-componente')
          end
        end
      end

      return { warning_messages: @warning_messages }
    end

    protected

    def api
      IeducarApi::PostDescriptiveExams.new(@post_data.to_api)
    end

    def post_by_step
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        next if classroom.unity_id != @post_data.school_calendar_step.school_calendar.unity_id
        next if classroom.exam_rule.opinion_type != OpinionTypes::BY_STEP

        exams = DescriptiveExamStudent.by_classroom_and_step(classroom, @post_data.school_calendar_step.id)
        exams.each do |exam|
          descriptive_exams[classroom.api_code][exam.student.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_year
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.classrooms.uniq.each do |classroom|
        next if classroom.unity_id != @post_data.school_calendar_step.school_calendar.unity_id
        next if classroom.exam_rule.opinion_type != OpinionTypes::BY_YEAR

        exams = DescriptiveExamStudent.by_classroom(classroom)
        exams.each do |exam|
          descriptive_exams[classroom.api_code][exam.student.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_year_and_discipline
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next if classroom.unity_id != @post_data.school_calendar_step.school_calendar.unity_id
        next if classroom.exam_rule.opinion_type != OpinionTypes::BY_YEAR_AND_DISCIPLINE

        exams = DescriptiveExamStudent.by_classroom_and_discipline(classroom, discipline)
        exams.each do |exam|
          descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    def post_by_step_and_discipline
      descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

      teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
        classroom = teacher_discipline_classroom.classroom
        discipline = teacher_discipline_classroom.discipline

        next if classroom.unity_id != @post_data.school_calendar_step.school_calendar.unity_id
        next if classroom.exam_rule.opinion_type != OpinionTypes::BY_STEP_AND_DISCIPLINE

        exams = DescriptiveExamStudent.by_classroom_discipline_and_step(classroom, discipline, @post_data.school_calendar_step.id)
        exams.each do |exam|
          descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]["valor"] = exam.value
        end
      end

      descriptive_exams
    end

    private

    def teacher
      @post_data.author.current_teacher
    end
  end
end
