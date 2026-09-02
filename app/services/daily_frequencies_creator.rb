class DailyFrequenciesCreator
  # Chave natural do diário: as mesmas colunas do índice único e as mesmas usadas no find_or_create_by.
  # Uma lista só porque chave do lock e condição da busca precisam casar — divergindo, o lock protege
  # uma linha diferente da que a busca resolve.
  DAILY_FREQUENCY_KEY_COLUMNS = %i[classroom_id frequency_date period discipline_id class_number].freeze

  attr_reader :daily_frequencies

  def initialize(params)
    @params = params
    @class_numbers = params.delete(:class_numbers) || [nil]
    @origin = params.delete(:origin) || OriginTypes::API_V2
    @params[:frequency_date] ||= Time.zone.today
  end

  def self.find_or_create!(params)
    new(params).find_or_create!
  end

  def find_or_create!
    @daily_frequencies = @class_numbers.map do |class_number|
      find_or_create_daily_frequency_with_students(@params.merge(class_number: class_number))
    end.compact
  end

  private

  # Requisições simultâneas para o mesmo diário (o endpoint da API recebe um aluno por requisição)
  # disputariam o INSERT do diário e o de cada aluno, e as perdedoras violariam os índices únicos.
  # O lock pela chave natural faz a segunda esperar a primeira terminar e encontrar as linhas prontas.
  # Escritas que não passam por aqui — o diário pela web e a gravação do aluno feita pelo próprio
  # controller da API depois deste retorno — continuam cobertas pelo retry do lock.
  def find_or_create_daily_frequency_with_students(params)
    key_attributes = params.slice(*DAILY_FREQUENCY_KEY_COLUMNS)

    daily_frequency = AdvisoryTransactionLock.call(daily_frequency_lock_key(key_attributes)) do
      find_or_create_daily_frequency(params, key_attributes).tap do |record|
        find_or_create_daily_frequency_students(record) if record.persisted?
      end
    end

    return daily_frequency if daily_frequency && daily_frequency.persisted?

    log_unpersisted_daily_frequency(daily_frequency, params)
    nil
  end

  # Os valores passam pelo cast das colunas para que texto e Date, ou texto e inteiro, gerem a mesma
  # chave: o worker manda Date e inteiro, o controller da API manda os dois como texto.
  def daily_frequency_lock_key(key_attributes)
    values = DAILY_FREQUENCY_KEY_COLUMNS.map do |column|
      DailyFrequency.type_for_attribute(column.to_s).cast(key_attributes[column])
    end

    ['daily_frequency', *values].join(':')
  end

  # As validações do diário reprovam de rotina (etapa fechada, dia não letivo, data futura por relógio
  # errado do aparelho) e o objeto de erros é a única coisa que diz qual delas foi.
  def log_unpersisted_daily_frequency(daily_frequency, params)
    reason = daily_frequency ? daily_frequency.errors.full_messages.to_sentence : 'transação desfeita'

    Rails.logger.error(
      "[#{self.class}] diário não criado (turma: #{params[:classroom_id]}, " \
      "data: #{params[:frequency_date]}, aula: #{params[:class_number]}): #{reason}"
    )
  end

  def find_or_create_daily_frequency(params, key_attributes)
    DailyFrequency.create_with(
      params.slice(
        :unity_id,
        :school_calendar,
        :owner_teacher_id
      ).merge(
        origin: @origin
      )
    ).find_or_create_by(key_attributes)
  end

  def find_or_create_daily_frequency_students(daily_frequency)
    existing_student_ids = daily_frequency.students.map(&:student_id)
    student_enrollments = student_enrollments(daily_frequency).reject do |student_enrollment|
      existing_student_ids.include?(student_enrollment.student_id)
    end

    return if student_enrollments.empty?

    absence_justifications = AbsenceJustifiedOnDate.call(
      students: student_enrollments.map(&:student_id),
      date: daily_frequency.frequency_date,
      end_date: daily_frequency.frequency_date,
      classroom: daily_frequency.classroom_id,
      period: daily_frequency.period
    )

    student_enrollments.each do |student_enrollment|
      find_or_create_daily_frequency_student(daily_frequency, student_enrollment, absence_justifications)
    end
  end

  def find_or_create_daily_frequency_student(daily_frequency, student_enrollment, absence_justifications)
    daily_frequency.students.find_or_create_by(student_id: student_enrollment.student_id) do |daily_frequency_student|
      absence_justification = absence_justifications[daily_frequency_student.student_id] || {}
      absence_justification = absence_justification[daily_frequency.frequency_date] || {}
      absence_justification_student_id = absence_justification[0] || absence_justification[daily_frequency.class_number]

      if absence_justification_student_id
        daily_frequency_student.present = false
        daily_frequency_student.absence_justification_student_id = absence_justification_student_id
      else
        daily_frequency_student.present = true
      end

      daily_frequency_student.dependence = student_has_dependence?(student_enrollment.id, daily_frequency.discipline_id)
      daily_frequency_student.active = true
    end
  end

  # A lista é a mesma para todas as aulas do diário (turma, disciplina e data não mudam entre elas);
  # quem já tem registro em cada aula é filtrado por aula, em find_or_create_daily_frequency_students.
  def student_enrollments(daily_frequency)
    @student_enrollments ||= begin
      student_enrollments = StudentEnrollment.includes(:student)
                                             .by_classroom(daily_frequency.classroom)
                                             .by_discipline(daily_frequency.discipline)
                                             .by_date(@params[:frequency_date])
                                             .exclude_exempted_disciplines(
                                               daily_frequency.discipline_id,
                                               step_number(daily_frequency)
                                             )
                                             .active
                                             .ordered

      student_enrollments.by_period(student_period) if student_period

      student_enrollments.to_a
    end
  end

  def student_has_dependence?(student_enrollment_id, discipline_id)
    StudentEnrollmentDependence.by_student_enrollment(student_enrollment_id)
                               .by_discipline(discipline_id)
                               .any?
  end

  def step_number(daily_frequency)
    @step_number ||= StepsFetcher.new(daily_frequency.classroom)
                                 .step_by_date(daily_frequency.frequency_date)
                                 .try(:to_number) || 0
  end

  def student_period
    @params[:period] != Periods::FULL.to_i ? @params[:period] : nil
  end
end
