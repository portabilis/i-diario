module Api
  # Lê as notificações de infrequência que o motor do i-Diário já apurou — não
  # recalcula falta nem define régua própria.
  #
  # As DATAS das faltas viajam junto porque a contagem sozinha não diz quantos
  # afastamentos distintos houve: a mesma ausência pode gerar duas notificações
  # (pela régua das seguidas e pela das alternadas). Com as datas, quem consome
  # une, deduplica e agrupa em episódios.
  class InfrequencyTrackingsService
    Enrollment = Struct.new(:student_id, :classroom_id, :api_code, :joined_at, :left_at) do
      # As datas da enturmação são texto AAAA-MM-DD, vazio quando em aberto.
      def covers?(date)
        joined_at.present? && joined_at.to_date <= date && (left_at.blank? || left_at.to_date > date)
      end
    end

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
      trackings.map { |tracking| payload(tracking) }
    end

    private

    def trackings
      @trackings ||= InfrequencyTracking.includes(classroom: :unity)
                                        .joins(:classroom)
                                        .where(classrooms: { unity_id: unities.map(&:id) })
                                        .where(notification_date: start_at..end_at)
                                        .ordered
    end

    def payload(tracking)
      absences = tracking.absence_dates

      {
        student_api_code: student_api_codes[tracking.student_id],
        registration_api_code: registration_api_code(tracking),
        classroom_api_code: tracking.classroom.api_code,
        unity_api_code: tracking.classroom.unity.api_code,
        notification_type: tracking.notification_type,
        notification_date: tracking.notification_date.iso8601,
        absence_dates: absences,
        absences_count: absences.size
      }
    end

    # Sem o escopo padrão de Student (`kept`): a notificação de um aluno depois
    # unificado continua na tela do i-Diário e continua aqui, com o api_code
    # dele — e não com um nulo que ninguém consegue atribuir.
    def student_api_codes
      @student_api_codes ||= Student.unscoped
                                    .where(id: trackings.map(&:student_id).uniq)
                                    .pluck(:id, :api_code)
                                    .to_h
    end

    # A matrícula (`matricula_id` no i-Educar) do estudante naquela turma. O
    # mesmo estudante pode ter mais de uma na mesma turma (saiu e voltou):
    # vence a enturmação vigente na data da notificação; sem nenhuma vigente,
    # a mais recente.
    def registration_api_code(tracking)
      candidates = enrollments.fetch([tracking.student_id, tracking.classroom_id], [])
      chosen = candidates.find { |enrollment| enrollment.covers?(tracking.notification_date) } || candidates.last

      chosen&.api_code
    end

    # Resolvido de uma vez: por linha, seria uma consulta por notificação. A
    # ordem por `joined_at` é o que torna "a mais recente" determinístico.
    def enrollments
      @enrollments ||=
        StudentEnrollment.joins(student_enrollment_classrooms: :classrooms_grade)
                         .where(student_id: trackings.map(&:student_id).uniq)
                         .where(classrooms_grades: { classroom_id: trackings.map(&:classroom_id).uniq })
                         .order('student_enrollment_classrooms.joined_at', 'student_enrollments.id')
                         .pluck(
                           :student_id,
                           'classrooms_grades.classroom_id',
                           'student_enrollments.api_code',
                           'student_enrollment_classrooms.joined_at',
                           'student_enrollment_classrooms.left_at'
                         )
                         .map { |row| Enrollment.new(*row) }
                         .group_by { |enrollment| [enrollment.student_id, enrollment.classroom_id] }
    end
  end
end
