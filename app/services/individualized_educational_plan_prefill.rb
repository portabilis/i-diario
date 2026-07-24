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
    # Avalia guardians primeiro: ele é quem sinaliza @guardians_unavailable, lido abaixo.
    guardians_names = guardians
    {
      birth_date: birth_date,
      diagnosis: diagnosis,
      guardians: guardians_names,
      guardians_unavailable: @guardians_unavailable || false,
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

  # Nomes dos responsáveis: vêm da API do i-Educar em tempo real (não há coluna local).
  # Distingue "aluno sem responsáveis" de "não foi possível buscar": no segundo caso sinaliza
  # @guardians_unavailable, para a tela avisar em vez de exibir um campo vazio.
  def guardians
    return mark_guardians_unavailable if student.api_code.blank?

    response = IeducarApi::Students.new(IeducarApiConfiguration.current.to_api).fetch_by_id(student.api_code)

    return mark_guardians_unavailable unless response_matches_student?(response)

    Array(response['nomes_responsaveis']).join(', ').presence
  rescue IeducarApi::Base::NetworkException, IeducarApi::Base::GenericError => e
    Rails.logger.error("PEI prefill - falha ao buscar responsáveis (student #{student.id}): #{e.message}")
    mark_guardians_unavailable
  end

  # Marca que não foi possível obter os responsáveis (sem api_code, API fora ou resposta
  # inesperada). Retorna nil: o valor fica vazio, mas a flag informa o motivo à tela.
  def mark_guardians_unavailable
    @guardians_unavailable = true
    nil
  end

  def response_matches_student?(response)
    response.is_a?(Hash) && response['id'].to_s == student.api_code.to_s
  end

  # Turno efetivo do aluno na turma do perfil: o período da matrícula na turma
  # (student_enrollment_classrooms.period) prevalece quando presente — motivado pela turma
  # integral, mas vale para qualquer turma; sem ele, cai no turno da própria turma.
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
