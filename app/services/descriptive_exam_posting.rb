class DescriptiveExamPosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    post_by_students(classroms_for_opinion_by_step, 'pareceres-por-etapa-geral')
    post_by_students(classroms_for_opinion_by_step_and_discipline, 'pareceres-por-etapa-e-componente')
    post_by_students(classroms_for_opinion_by_year, 'pareceres-anual-geral')
    post_by_students(classroms_for_opinion_by_year_and_discipline, 'pareceres-anual-por-componente')
  end

  protected

  attr_accessor :posting

  def api
    IeducarApi::PostDescriptiveExams.new(posting.to_api)
  end

  def classroms_for_opinion_by_step
    classrooms = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.classrooms.uniq.each do |classroom|
      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      opinion_type = classroom.exam_rule.opinion_type

      if opinion_type != OpinionTypes::BY_STEP
        next
      end

      exams = DescriptiveExamStudent.by_classroom_and_step(classroom, posting.school_calendar_step.id)

      exams.each do |exam|

        classrooms[classroom.api_code]["turma_id"] = classroom.api_code
        classrooms[classroom.api_code]["alunos"][exam.student.api_code]["aluno_id"] = exam.student.api_code
        classrooms[classroom.api_code]["alunos"][exam.student.api_code]["parecer"] = exam.value
      end

    end
    classrooms
  end

  def classroms_for_opinion_by_year
    classrooms = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.classrooms.uniq.each do |classroom|
      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      opinion_type = classroom.exam_rule.opinion_type

      if opinion_type != OpinionTypes::BY_YEAR
        next
      end

      exams = DescriptiveExamStudent.by_classroom(classroom)

      exams.each do |exam|
        classrooms[classroom.api_code]["turma_id"] = classroom.api_code
        classrooms[classroom.api_code]["alunos"][exam.student.api_code]["aluno_id"] = exam.student.api_code
        classrooms[classroom.api_code]["alunos"][exam.student.api_code]["parecer"] = exam.value
      end

    end
    classrooms
  end

  def classroms_for_opinion_by_year_and_discipline
    classrooms = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      next if teacher_discipline_classroom.classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline

      opinion_type = classroom.exam_rule.opinion_type

      if opinion_type != OpinionTypes::BY_YEAR_AND_DISCIPLINE
        next
      end

      exams = DescriptiveExamStudent.by_classroom_and_discipline(classroom, discipline)

      exams.each do |exam|
        classrooms[classroom.api_code]["turma_id"] = classroom.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["aluno_id"] = exam.student.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["componentes_curriculares"][discipline.api_code]["componente_curricular_id"] = discipline.api_code

        classrooms[classroom.api_code]["alunos"][exam.student.api_code]["componentes_curriculares"][discipline.api_code]["parecer"] = exam.value
      end
    end
    classrooms
  end

  def classroms_for_opinion_by_step_and_discipline
    classrooms = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      next if teacher_discipline_classroom.classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline

      opinion_type = classroom.exam_rule.opinion_type

      if opinion_type != OpinionTypes::BY_STEP_AND_DISCIPLINE
        next
      end

      exams = DescriptiveExamStudent.by_classroom_discipline_and_step(classroom, discipline, posting.school_calendar_step.id)

      exams.each do |exam|
        classrooms[classroom.api_code]["turma_id"] = classroom.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["aluno_id"] = exam.student.api_code
          classrooms[classroom.api_code]["alunos"][exam.student.api_code]["componentes_curriculares"][discipline.api_code]["componente_curricular_id"] = discipline.api_code

        classrooms[classroom.api_code]["alunos"][exam.student.api_code]["componentes_curriculares"][discipline.api_code]["parecer"] = exam.value

      end
    end
    classrooms
  end

  private

  def post_by_students(classrooms, resource)
    classrooms.each do |key_classroom, value_classroom|
      value_classroom['alunos'].each do |key_student, value_student|
        params = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        params['turma_id'] = key_classroom
        params['alunos'][key_student] = value_student

        api.send_post(turmas: { key_classroom => params }, etapa: posting.school_calendar_step.to_number, resource: resource)
      end
    end
  end
end
