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
  class FrequencyRecordCompletenessService
    attr_reader :unity_api_code, :start_at, :end_at

    def self.call(unity_api_code:, start_at:, end_at:)
      new(unity_api_code: unity_api_code, start_at: start_at, end_at: end_at).call
    end

    def initialize(unity_api_code:, start_at:, end_at:)
      @unity_api_code = unity_api_code
      @start_at = start_at
      @end_at = end_at
    end

    def call
      classrooms.map do |classroom|
        {
          classroom_api_code: classroom.api_code,
          classroom_name: classroom.description,
          unity_api_code: unity_api_code,
          school_days: school_days_count,
          days_with_record: days_with_record.fetch(classroom.id, 0),
          active_enrollments: active_enrollments.fetch(classroom.id, 0)
        }
      end
    end

    private

    def unity
      @unity ||= Unity.find_by(api_code: unity_api_code)
    end

    def classrooms
      @classrooms ||= unity ? Classroom.where(unity_id: unity.id, year: year) : Classroom.none
    end

    # O ano vem do próprio período pedido: turma é do ano letivo.
    def year
      @year ||= start_at.to_date.year
    end

    # O denominador: os dias letivos que a unidade tem no período.
    def school_days_count
      @school_days_count ||= UnitySchoolDay.by_unity_id(unity&.id)
                                           .by_date_between(start_at, end_at)
                                           .count
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
    def active_enrollments
      @active_enrollments ||=
        StudentEnrollmentClassroom.joins(:classrooms_grade)
                                  .where(classrooms_grades: { classroom_id: classrooms.map(&:id) })
                                  .where(discarded_at: nil)
                                  .group('classrooms_grades.classroom_id')
                                  .count
    end
  end
end
