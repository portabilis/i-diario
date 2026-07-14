# Monta os dados de identificação do aluno (seção 1 do PEI) a partir de fontes já
# sincronizadas do i-Educar. Apenas os responsáveis são buscados na API em tempo real
# (não há coluna local para eles).
class IndividualizedEducationalPlanPrefill
  def initialize(student, unity, year)
    @student = student
    @unity = unity
    @year = year
  end

  def self.student_data(student, unity: nil, year: nil)
    new(student, unity, year).student_data
  end

  def student_data
    {
      birth_date: student.birth_date&.strftime('%d/%m/%Y'),
      diagnosis: diagnosis,
      guardians: guardians,
      classrooms: classrooms
    }
  end

  private

  attr_reader :student, :unity, :year

  def diagnosis
    student.deficiencies.map(&:name).join(', ').presence
  end

  # Nomes dos responsáveis vêm da API do i-Educar em tempo real (não há coluna local).
  # Campo opcional: qualquer falha da API externa não pode quebrar o preenchimento do formulário,
  # por isso o rescue amplo em torno da única chamada externa (com log + Honeybadger).
  def guardians
    return if student.api_code.blank?

    response = IeducarApi::Students.new(IeducarApiConfiguration.current.to_api).fetch_by_id(student.api_code)

    Array(response && response['nomes_responsaveis']).join(', ').presence
  rescue StandardError => e
    Rails.logger.error("PEI prefill - falha ao buscar responsáveis (student #{student.id}): #{e.message}")
    Honeybadger.notify(e)
    nil
  end

  # Turmas do aluno na escola do perfil, no ano, com o turno efetivo do aluno.
  # `teacher` (regente) virá do i-Educar (D20) — pendente da entrega deles.
  def classrooms
    return [] if unity.blank?

    student_classrooms = student.classrooms.by_unity_id(unity.id).by_year(year).distinct
    periods = student_periods_by_classroom(student_classrooms.map(&:id))

    student_classrooms.map do |classroom|
      effective_period = periods[classroom.id] || classroom.period

      {
        id: classroom.id,
        name: classroom.description,
        shift: (Periods.t(effective_period.to_s) if effective_period.present?),
        teacher: nil # regente virá do i-Educar (D20)
      }
    end
  end

  # Turno efetivo do aluno por turma: em turma integral, o aluno pode estudar em um turno
  # específico (student_enrollment_classrooms.period); quando ausente, cai no turno da turma.
  def student_periods_by_classroom(classroom_ids)
    return {} if classroom_ids.empty?

    StudentEnrollmentClassroom
      .by_student(student.id)
      .active
      .joins(classrooms_grade: :classroom)
      .where(classrooms: { id: classroom_ids })
      .where.not(period: nil)
      .pluck('classrooms.id', :period)
      .to_h
  end
end
