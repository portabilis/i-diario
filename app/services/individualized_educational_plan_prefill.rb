# Monta os dados de identificação do aluno (seção 1 do PEI) a partir de fontes já
# sincronizadas do i-Educar. Apenas os responsáveis são buscados na API em tempo real
# (não há coluna local para eles).
class IndividualizedEducationalPlanPrefill
  def initialize(student, classroom)
    @student = student
    @classroom = classroom
  end

  def self.student_data(student, classroom: nil)
    new(student, classroom).student_data
  end

  # Só dados locais, sem chamada externa — usado no request síncrono (edit/create/update).
  # Exclui "responsáveis", que dependem do i-Educar (timeout de 240s) e são buscados via AJAX.
  def self.local_student_data(student, classroom: nil)
    new(student, classroom).local_student_data
  end

  def student_data
    {
      birth_date: birth_date,
      diagnosis: diagnosis,
      guardians: guardians,
      shift: shift
    }
  end

  def local_student_data
    { birth_date: birth_date, diagnosis: diagnosis, shift: shift }
  end

  private

  attr_reader :student, :classroom

  def birth_date
    student.birth_date&.strftime('%d/%m/%Y')
  end

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

  # Turno efetivo do aluno na turma do perfil: em turma integral, o aluno pode estudar em um
  # turno específico (student_enrollment_classrooms.period); quando ausente, cai no turno da turma.
  def shift
    return if classroom.blank?

    period = StudentEnrollmentClassroom
             .by_student(student.id)
             .active
             .joins(classrooms_grade: :classroom)
             .where(classrooms: { id: classroom.id })
             .where.not(period: nil)
             .pluck(:period)
             .first || classroom.period

    Periods.t(period.to_s) if period.present?
  end
end
