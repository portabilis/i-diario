module Api
  class MonthlyFrequenciesService
    attr_reader :classrooms_api_code, :year, :months, :students_api_code

    def self.call(classrooms_api_code:, year:, months:, students_api_code: nil)
      new(
        classrooms_api_code: classrooms_api_code,
        year: year,
        months: months,
        students_api_code: students_api_code
      ).call
    end

    def initialize(classrooms_api_code:, year:, months:, students_api_code: nil)
      @classrooms_api_code = Array(classrooms_api_code).map(&:to_s).reject(&:blank?)
      @year = year.to_i
      @months = Array(months).map(&:to_i).uniq.sort
      @students_api_code = students_api_code.present? ? Array(students_api_code).map(&:to_s) : nil
    end

    def call
      classrooms.map { |classroom| build_classroom_payload(classroom) }
    end

    private

    def classrooms
      @classrooms ||= Classroom
                      .where(api_code: classrooms_api_code, year: year)
                      .order(:api_code)
    end

    def period_start
      @period_start ||= Date.new(year, months.first, 1)
    end

    def period_end
      @period_end ||= Date.new(year, months.last, 1).end_of_month
    end

    def frequencies_by_classroom_id
      @frequencies_by_classroom_id ||= aggregated_frequencies.group_by { |frequency| frequency.aggregated_classroom_id.to_i }
    end

    def build_classroom_payload(classroom)
      classroom_frequencies = frequencies_by_classroom_id[classroom.id] || []
      frequencies_by_month = classroom_frequencies.group_by { |frequency| frequency.month.to_i }

      {
        classroom_id: classroom.api_code,
        classroom_name: classroom.description,
        year: year,
        months: months.map { |month| build_month_payload(month, frequencies_by_month[month] || []) }
      }
    end

    def build_month_payload(month, student_frequencies)
      {
        month: month,
        students: student_frequencies.map { |frequency| build_student_row(frequency) }
      }
    end

    def aggregated_frequencies
      return [] if classrooms.empty?

      scope = DailyFrequencyStudent
              .active
              .joins(:daily_frequency, :student)
              .where(daily_frequencies: { classroom_id: classrooms.map(&:id),
                                          frequency_date: period_start..period_end })
              .where('EXTRACT(MONTH FROM daily_frequencies.frequency_date) IN (?)', months)
              .group(
                'daily_frequencies.classroom_id',
                'students.api_code',
                'students.name',
                'EXTRACT(MONTH FROM daily_frequencies.frequency_date)'
              )
              .select(
                'daily_frequencies.classroom_id AS aggregated_classroom_id',
                'students.api_code AS student_api_code',
                'students.name AS student_name',
                'EXTRACT(MONTH FROM daily_frequencies.frequency_date) AS month',
                "SUM(CASE WHEN #{counts_as_presence_sql} THEN 1 ELSE 0 END) AS presences",
                "SUM(CASE WHEN #{counts_as_presence_sql} THEN 0 ELSE 1 END) AS absences"
              )
              .order('UPPER(students.name)')

      return scope if students_api_code.blank?

      scope.where(students: { api_code: students_api_code })
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

    def build_student_row(frequency)
      presences = frequency.presences.to_i
      absences = frequency.absences.to_i
      total = presences + absences

      {
        student_id: frequency.student_api_code,
        student_name: frequency.student_name,
        presences: presences,
        absences: absences,
        total_records: total,
        frequency_percentage: calculate_percentage(presences, total)
      }
    end

    def calculate_percentage(presences, total)
      return nil if total.zero?

      ((presences.to_f / total) * 100).round(2)
    end
  end
end
