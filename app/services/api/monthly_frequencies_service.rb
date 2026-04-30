module Api
  class MonthlyFrequenciesService
    attr_reader :student_enrollment_api_code, :months

    def self.call(student_enrollment_api_code:, months:)
      new(
        student_enrollment_api_code: student_enrollment_api_code,
        months: months
        ).call
    end

    def initialize(student_enrollment_api_code:, months:)
      @student_enrollment_api_code = Array(student_enrollment_api_code).map(&:to_s).reject(&:blank?)
      @months = Array(months).map(&:to_i).uniq.sort
    end

    def call
      enrollments_info.map { |enrollment| build_enrollment_payload(enrollment) }
    end

    private

    def enrollments_info
      @enrollments_info ||= StudentEnrollment
                            .joins(:student)
                            .joins(student_enrollment_classrooms: { classrooms_grade: [:classroom, { grade: :course }] })
                            .where(student_enrollments: { api_code: student_enrollment_api_code })
                            .where(student_enrollment_classrooms: { discarded_at: nil })
                            .group(
                              'student_enrollments.api_code',
                              'students.name',
                              'classrooms.year',
                              'courses.description'
                            )
                            .select(
                              'student_enrollments.api_code AS enrollment_api_code',
                              'students.name AS student_name',
                              'classrooms.year AS year',
                              'courses.description AS course_name'
                            )
                            .order('UPPER(courses.description), UPPER(students.name)')
    end

    def enrollment_years
      @enrollment_years ||= enrollments_info.map { |enrollment| enrollment.year.to_i }.uniq
    end

    def frequencies_by_enrollment_and_month
      @frequencies_by_enrollment_and_month ||= aggregated_frequencies.each_with_object({}) do |frequency, hash|
        hash[frequency.enrollment_api_code] ||= {}
        hash[frequency.enrollment_api_code][frequency.month.to_i] = frequency
      end
    end

    def aggregated_frequencies
      return [] if enrollments_info.empty?

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
        .where('EXTRACT(YEAR FROM daily_frequencies.frequency_date) IN (?)', enrollment_years)
        .where('EXTRACT(MONTH FROM daily_frequencies.frequency_date) IN (?)', months)
        .group(
          'student_enrollments.api_code',
          'EXTRACT(MONTH FROM daily_frequencies.frequency_date)'
        )
        .select(
          'student_enrollments.api_code AS enrollment_api_code',
          'EXTRACT(MONTH FROM daily_frequencies.frequency_date) AS month',
          "SUM(CASE WHEN #{counts_as_presence_sql} THEN 1 ELSE 0 END) AS presences",
          "SUM(CASE WHEN #{counts_as_presence_sql} THEN 0 ELSE 1 END) AS absences"
        )
    end

    def counts_as_presence_sql
      if ignore_justified_absences?
        'daily_frequency_students.present = true OR ' \
          'daily_frequency_students.absence_justification_student_id IS NOT NULL'
      else
        'daily_frequency_students.present = true'
      end
    end

    def ignore_justified_absences?
      return @ignore_justified_absences if defined?(@ignore_justified_absences)

      @ignore_justified_absences = GeneralConfiguration.current.do_not_send_justified_absence
    end

    def build_enrollment_payload(enrollment)
      {
        course_name: enrollment.course_name,
        student_enrollment_id: enrollment.enrollment_api_code,
        student_name: enrollment.student_name,
        months: months.each_with_object({}) do |month, hash|
          hash[month] = month_percentage(enrollment.enrollment_api_code, month)
        end
      }
    end

    def month_percentage(enrollment_api_code, month)
      frequency = frequencies_by_enrollment_and_month.dig(enrollment_api_code, month)

      presences = frequency&.presences.to_i
      absences = frequency&.absences.to_i
      total = presences + absences

      calculate_percentage(presences, total)
    end

    def calculate_percentage(presences, total)
      return nil if total.zero?

      ((presences.to_f / total) * 100).round(2)
    end
  end
end
