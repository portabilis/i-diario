module Api
  # Lê as notificações de infrequência que o motor do i-Diário já apurou — não
  # recalcula falta nem define régua própria.
  #
  # As DATAS das faltas viajam junto porque a contagem sozinha não diz quantos
  # afastamentos distintos houve: a mesma ausência pode gerar duas notificações
  # (pela régua das seguidas e pela das alternadas). Com as datas, quem consome
  # une, deduplica e agrupa em episódios.
  class InfrequencyTrackingsService
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
      trackings.map { |tracking| payload(tracking) }
    end

    private

    def trackings
      @trackings ||= InfrequencyTracking.includes(:student, classroom: :unity)
                                        .joins(classroom: :unity)
                                        .where(unities: { api_code: unity_api_code })
                                        .where(notification_date: start_at..end_at)
                                        .ordered
    end

    def payload(tracking)
      absences = absence_dates(tracking)

      {
        student_api_code: tracking.student&.api_code,
        registration_api_code: registration_api_codes[[tracking.student_id, tracking.classroom_id]],
        classroom_api_code: tracking.classroom&.api_code,
        unity_api_code: tracking.classroom&.unity&.api_code,
        notification_type: tracking.notification_type,
        notification_date: tracking.notification_date&.iso8601,
        absence_dates: absences,
        absences_count: absences.size
      }
    end

    # O mesmo dia aparece uma vez por professor que registrou a falta.
    def absence_dates(tracking)
      Array(tracking.notification_data)
        .flat_map { |registro| registro['absences'] || registro[:absences] || [] }
        .uniq
        .sort
    end

    # ref_cod_matricula do i-Educar = api_code da matrícula do estudante
    # naquela turma. Resolvido de uma vez: por linha, seria uma consulta por
    # notificação.
    #
    # A ordem é explícita porque o mesmo estudante pode ter mais de uma
    # matrícula viva na mesma turma; sem ela, qual delas vence dependeria da
    # ordem que o banco devolvesse, e a resposta mudaria entre chamadas iguais.
    def registration_api_codes
      @registration_api_codes ||=
        StudentEnrollment.joins(student_enrollment_classrooms: :classrooms_grade)
                         .where(student_id: trackings.map(&:student_id).uniq)
                         .where(classrooms_grades: { classroom_id: trackings.map(&:classroom_id).uniq })
                         .order('student_enrollments.id')
                         .pluck(:student_id, 'classrooms_grades.classroom_id', 'student_enrollments.api_code')
                         .each_with_object({}) do |(student_id, classroom_id, api_code), mapa|
                           mapa[[student_id, classroom_id]] ||= api_code
                         end
    end
  end
end
