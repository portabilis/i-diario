class ConceptualExamPosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    if classrooms = post_classrooms
      api.send_post(turmas: classrooms, etapa: posting.school_calendar_step.to_number)
    else
      raise IeducarApi::Base::ApiError.new('Nenhuma turma com tipo de avaliações conceituais encontrada.')
    end
  end

  protected

  attr_accessor :posting

  def api
    IeducarApi::PostExams.new(posting.to_api)
  end

  def post_classrooms
    classrooms = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

    teacher = posting.author.teacher

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      next if teacher_discipline_classroom.classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id

      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline

      score_type = classroom.exam_rule.score_type

      if score_type != ScoreTypes::CONCEPT
        next
      end

      exams = ConceptualExamStudent.by_classroom_discipline_and_step(classroom, discipline, posting.school_calendar_step.id)
      if exams.any?
        exams.each do |exam|
          classrooms[classroom.api_code]['turma_id'] = classroom.api_code
          classrooms[classroom.api_code]['alunos'][exam.student.api_code]['aluno_id'] = exam.student.api_code
          classrooms[classroom.api_code]['alunos'][exam.student.api_code]['componentes_curriculares'][discipline.api_code]['componente_curricular_id'] = discipline.api_code
          classrooms[classroom.api_code]['alunos'][exam.student.api_code]['componentes_curriculares'][discipline.api_code]['valor'] = exam.value
        end
      else
        raise IeducarApi::Base::ApiError.new("Não foi possível enviar as avaliações conceituais da turma #{classroom} pois não foram lançados dos os conceitos.")
      end
    end
    classrooms
  end
end
