class ConceptualExamPosting
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    if params = fetch_params
      puts '************************'
      puts params.to_json
      puts '************************'

      params.each do |key, value|
        api.send_post(
          turmas: { key => value },
          etapa: posting.school_calendar_step.to_number
        )
      end
    else
      raise IeducarApi::Base::ApiError.new(
        'Nenhum lançamento de avaliação conceitual encontrado.'
      )
    end
  end

  private

  attr_accessor :posting

  def api
    IeducarApi::PostExams.new(posting.to_api)
  end

  def fetch_params
    params = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

    conceptual_exams = ConceptualExam.by_teacher(posting.author.teacher)
      .by_unity(posting.school_calendar_step.school_calendar.unity)
      .by_school_calendar_step(posting.school_calendar_step)

    conceptual_exams.each do |conceptual_exam|
      conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
        classroom_api_code = conceptual_exam.classroom.api_code
        student_api_code = conceptual_exam.student.api_code
        discipline_api_code = conceptual_exam_value.discipline.api_code

        params[classroom_api_code]['turma_id'] = classroom_api_code
        params[classroom_api_code]['alunos'][student_api_code]['aluno_id'] = student_api_code
        params[classroom_api_code]['alunos'][student_api_code]['componentes_curriculares'][discipline_api_code]['componente_curricular_id'] = discipline_api_code
        params[classroom_api_code]['alunos'][student_api_code]['componentes_curriculares'][discipline_api_code]['valor'] = conceptual_exam_value.value
      end
    end

    params
  end
end
