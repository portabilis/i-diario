module Api
  # Quanto do registro de frequência foi lançado, turma a turma, no período.
  #
  # Serve para quem lê distinguir dois problemas que se parecem no número:
  # turma com frequência baixa de verdade e turma que simplesmente não teve a
  # chamada lançada. Sem isso, escola que não lança aparece como escola boa.
  #
  # O retorno é POR TURMA, e de propósito: "% de turmas em dia" só se calcula a
  # partir da turma; o caminho contrário não existe. Turma sem nenhum
  # lançamento entra na lista com zero — some-la seria esconder justamente o
  # caso que motiva o indicador.
  #
  # O denominador (`school_days`) é o calendário da UNIDADE da turma, não o da
  # turma: evento por turma, série ou curso não mexe nos dias letivos da
  # unidade, e turma com calendário próprio recebe aqui o corte da rede. É a
  # régua do Acompanhamento Pedagógico, e quem lê precisa saber que é ela.
  class FrequencyRecordCompletenessService
    attr_reader :unities, :start_at, :end_at

    def self.call(unities:, start_at:, end_at:)
      new(unities: unities, start_at: start_at, end_at: end_at).call
    end

    def initialize(unities:, start_at:, end_at:)
      @unities = unities
      @start_at = start_at
      @end_at = end_at
    end

    def call
      classrooms.map do |classroom|
        {
          classroom_api_code: classroom.api_code,
          classroom_name: classroom.description,
          unity_api_code: unity_api_codes[classroom.unity_id],
          school_days: school_days.fetch([classroom.unity_id, classroom.year], 0),
          days_with_record: days_with_record.fetch(classroom.id, 0),
          active_enrollments: active_enrollments.fetch(classroom.id, 0)
        }
      end
    end

    private

    def unity_ids
      @unity_ids ||= unities.map(&:id)
    end

    def unity_api_codes
      @unity_api_codes ||= unities.map { |unity| [unity.id, unity.api_code] }.to_h
    end

    # Turma é do ano letivo: um período que cruza o ano traz as turmas dos dois
    # anos, cada uma com os dias letivos do seu próprio ano.
    def classrooms
      @classrooms ||= Classroom.where(unity_id: unity_ids, year: start_at.year..end_at.year).to_a
    end

    # Os dias letivos do período por unidade e ano — o denominador de cada
    # turma sai daqui pela dupla (unidade da turma, ano da turma).
    def school_days
      @school_days ||=
        UnitySchoolDay.where(unity_id: unity_ids)
                      .by_date_between(start_at, end_at)
                      .group(:unity_id, 'EXTRACT(year FROM school_day)')
                      .count
                      .each_with_object({}) do |((unity_id, year), total), map|
                        map[[unity_id, year.to_i]] = total
                      end
    end

    # Dias distintos em que a turma teve ao menos um lançamento — qualquer
    # autor. Um dia conta uma vez, mesmo com várias disciplinas lançadas.
    def days_with_record
      @days_with_record ||= DailyFrequency.where(classroom_id: classrooms.map(&:id))
                                          .where(frequency_date: start_at..end_at)
                                          .distinct
                                          .group(:classroom_id)
                                          .count(:frequency_date)
    end

    # Existe para quem lê descartar turma fantasma do cálculo: turma sem
    # matrícula em 0% derrubaria a escola inteira abaixo do corte.
    #
    # Conta as matrículas com enturmação vigente em algum dia do período, uma
    # vez cada: turma multisseriada tem um `classrooms_grade` por série, e a
    # mesma matrícula apareceria em mais de um.
    def active_enrollments
      @active_enrollments ||=
        StudentEnrollmentClassroom.by_classroom(classrooms.map(&:id))
                                  .where('student_enrollment_classrooms.joined_at <= ?', end_at)
                                  .by_left_at_date(start_at)
                                  .group('classrooms_grades.classroom_id')
                                  .distinct
                                  .count(:student_enrollment_id)
    end
  end
end
