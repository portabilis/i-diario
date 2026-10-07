module Api
  class EnrollmentDailyFrequencyStatusesService
    attr_reader :student_enrollment_api_code, :start_at, :end_at, :limit

    def self.call(student_enrollment_api_code:, start_at: nil, end_at: nil, limit: nil)
      new(
        student_enrollment_api_code: student_enrollment_api_code,
        start_at: start_at,
        end_at: end_at,
        limit: limit
      ).call
    end

    def initialize(student_enrollment_api_code:, start_at: nil, end_at: nil, limit: nil)
      @student_enrollment_api_code = student_enrollment_api_code.to_s
      @start_at = start_at
      @end_at = end_at
      @limit = limit
    end

    def call
      student_enrollment

      daily_aggregates.each_with_object({}) do |row, hash|
        hash[row['date'].iso8601] = status_for(row)
      end
    end

    private

    def student_enrollment
      @student_enrollment ||= StudentEnrollment.find_by!(api_code: student_enrollment_api_code)
    end

    # O status do dia expõe a falta justificada como valor próprio ('justified'),
    # então a configuração do_not_send_justified_absence não se aplica aqui:
    # o fato vai cru e a régua de contagem é de quem consome.
    def daily_aggregates
      scope = base_scope
      scope = scope.where('daily_frequencies.frequency_date >= ?', start_at) if start_at
      scope = scope.where('daily_frequencies.frequency_date <= ?', end_at) if end_at
      scope = scope.limit(limit) if limit

      scope
        .group('daily_frequencies.frequency_date')
        .order('daily_frequencies.frequency_date DESC')
        .select(
          'daily_frequencies.frequency_date AS date',
          'SUM(CASE WHEN daily_frequency_students.present = TRUE THEN 1 ELSE 0 END) AS presences',
          "SUM(CASE WHEN COALESCE(daily_frequency_students.present, FALSE) = FALSE
                     AND daily_frequency_students.absence_justification_student_id IS NULL
               THEN 1 ELSE 0 END) AS unjustified_absences"
        )
    end

    def base_scope
      DailyFrequencyStudent
        .active
        .joins(:daily_frequency, :student)
        .joins(<<~SQL.squish)
          INNER JOIN student_enrollments
            ON student_enrollments.student_id = students.id
            AND student_enrollments.discarded_at IS NULL
          INNER JOIN student_enrollment_classrooms sec
            ON sec.student_enrollment_id = student_enrollments.id
            AND sec.discarded_at IS NULL
          INNER JOIN classrooms_grades cg
            ON cg.id = sec.classrooms_grade_id
        SQL
        .where(student_enrollments: { api_code: student_enrollment_api_code })
        .where('cg.classroom_id = daily_frequencies.classroom_id')
        .where('daily_frequencies.frequency_date >= CAST(sec.joined_at AS DATE)')
        .where(<<~SQL.squish)
          CASE WHEN COALESCE(sec.left_at, '') = '' THEN TRUE
               ELSE daily_frequencies.frequency_date < CAST(sec.left_at AS DATE)
          END
        SQL
    end

    # Dia com ao menos uma presença conta como presença (mesma régua do AbsenceCountService);
    # sem presença, o dia só é 'justified' quando nenhuma falta ficou sem justificativa.
    def status_for(row)
      if row['presences'].to_i.positive?
        'presence'
      elsif row['unjustified_absences'].to_i.positive?
        'absent'
      else
        'justified'
      end
    end
  end
end
