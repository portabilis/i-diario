# Monta os dados de identificação do aluno (seção 1 do PEI) a partir de fontes já
# sincronizadas do i-Educar. Responsáveis e laudos não têm cópia local: os dois são lidos
# do cadastro do aluno no i-Educar, na MESMA consulta.
class IndividualizedEducationalPlanPrefill
  def initialize(student, classroom)
    @student = student
    @classroom = classroom
  end

  def self.student_data(student, classroom: nil)
    new(student, classroom).student_data
  end

  # Só dados locais, sem chamada externa — usado no request síncrono (edit/create/update).
  # Exclui "responsáveis" e laudos, que dependem do i-Educar (timeout de 240s) e são
  # buscados via AJAX.
  def self.local_student_data(student, classroom: nil)
    new(student, classroom).local_student_data
  end

  # Só os laudos. Usado na tela de versão publicada, onde o restante vem congelado do
  # snapshot mas o laudo é sempre o que está hoje no cadastro do aluno.
  def self.medical_reports_data(student)
    new(student, nil).medical_reports_data
  end

  # Devolve o unavailable junto com a URL: sem ele, "não deu para consultar o cadastro" e "o
  # laudo não está mais lá" chegariam à tela do mesmo jeito, como URL em branco.
  def self.medical_report_lookup(student, name, created_at)
    new(student, nil).medical_report_lookup(name, created_at)
  end

  def student_data
    {
      birth_date: birth_date,
      diagnosis: diagnosis,
      guardians: guardians,
      guardians_unavailable: ieducar_student.nil?,
      shift: shift
    }.merge(medical_reports_data)
  end

  def local_student_data
    { birth_date: birth_date, diagnosis: diagnosis, shift: shift }
  end

  def medical_reports_data
    { medical_reports: medical_reports, medical_reports_unavailable: medical_reports_unavailable? }
  end

  def medical_report_lookup(name, created_at)
    return { url: nil, unavailable: false } if name.blank?

    { url: medical_report_url(name, created_at), unavailable: medical_reports_unavailable? }
  end

  private

  attr_reader :student, :classroom

  def birth_date
    student.birth_date&.strftime('%d/%m/%Y')
  end

  def diagnosis
    student.deficiencies.map(&:name).join(', ').presence
  end

  def guardians
    Array(ieducar_student && ieducar_student['nomes_responsaveis']).join(', ').presence
  end

  # Laudos anexados ao cadastro do aluno. A URL não é devolvida de propósito (expira em 5
  # minutos): a tela mostra nome e data, e resolve a URL no clique.
  #
  # O created_at vai junto porque o i-Educar não expõe id de arquivo e o nome não é único —
  # é o par (nome, data de envio) que identifica o laudo na hora de abrir.
  def medical_reports
    raw_medical_reports.map do |report|
      {
        name: report['original_name'],
        sent_at: formatted_date(report['created_at']),
        created_at: report['created_at']
      }
    end
  end

  # Sem a chave 'laudos' na resposta não dá para afirmar que o aluno não tem laudo: é o que
  # acontece com um i-Educar anterior à entrega dos laudos, ou se o campo for renomeado.
  def medical_reports_unavailable?
    ieducar_student.nil? || !ieducar_student.key?('laudos')
  end

  def medical_report_url(name, created_at)
    report = raw_medical_reports.find do |item|
      item['original_name'] == name && item['created_at'].to_s == created_at.to_s
    end

    report && report['url'].presence
  end

  def raw_medical_reports
    Array(ieducar_student && ieducar_student['laudos']).select { |report| report.is_a?(Hash) }
  end

  def formatted_date(value)
    Time.zone.parse(value.to_s)&.strftime('%d/%m/%Y')
  rescue ArgumentError
    nil
  end

  # Consulta o cadastro do aluno no i-Educar UMA vez por instância — responsáveis e laudos
  # saem da mesma resposta. nil significa "não foi possível obter" (aluno sem api_code,
  # entidade sem integração configurada, API fora ou resposta de outro aluno); a tela avisa,
  # em vez de exibir campo vazio como se o aluno não tivesse o dado.
  def ieducar_student
    return @ieducar_student if defined?(@ieducar_student)

    @ieducar_student = fetch_ieducar_student
  end

  def fetch_ieducar_student
    return if student.api_code.blank?

    response = IeducarApi::Students.new(IeducarApiConfiguration.current.to_api).fetch_by_id(student.api_code)

    return response if response_matches_student?(response)

    Rails.logger.error(
      "PEI prefill - resposta do i-Educar não corresponde ao aluno (student #{student.id}, " \
      "api_code #{student.api_code}, id recebido #{response.is_a?(Hash) ? response['id'].inspect : response.class})"
    )
    nil
  rescue IeducarApi::Base::ApiError => e
    # Único caminho que o IeducarApi::Base não reporta ao Honeybadger (configuração da
    # entidade incompleta ou URL inválida) — os demais já chegam lá antes de virar exceção.
    Honeybadger.notify(e, context: { student_id: student.id, api_code: student.api_code })
    log_ieducar_failure(e)
    nil
  rescue IeducarApi::Base::NetworkException, IeducarApi::Base::GenericError => e
    log_ieducar_failure(e)
    nil
  end

  def log_ieducar_failure(error)
    Rails.logger.error(
      "PEI prefill - falha ao consultar o cadastro do aluno no i-Educar (student #{student.id}): #{error.message}"
    )
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
