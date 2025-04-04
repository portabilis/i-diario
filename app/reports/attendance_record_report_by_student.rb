class AttendanceRecordReportByStudent < BaseReport
  class DailyFrequenciesNotFoundError < StandardError; end

  attr_accessor :classrooms, :enrollment_classrooms_list, :period, :start_at, :end_at

  def self.call(
    classrooms,
    enrollment_classrooms_list,
    period,
    start_at,
    end_at
  )
    new(
      classrooms,
      enrollment_classrooms_list,
      period,
      start_at,
      end_at
    ).call
  end

  def initialize(
    classrooms,
    enrollment_classrooms_list,
    period,
    start_at,
    end_at
  )
    super()
    @classrooms = classrooms
    @enrollment_classrooms_list = enrollment_classrooms_list
    @period = period
    @start_at = start_at
    @end_at = end_at
  end

  def call
    calculated_frequencies = calculate_percentage_of_presence

    classrooms.map do |classroom|
      students = enrollment_classrooms_list.select{ |student| student[:classroom_id].eql?(classroom.id) }
      frequencies_by_classroom = calculated_frequencies.detect do |student|
        student[:classroom].eql?(classroom.id)
      end

      next if frequencies_by_classroom.blank? || students.empty?

      {
        classroom.id => {
          classroom_name: classroom.description,
          grade_name: classroom.grades.first.description,
          students: students.map do |student|
            {
              student_id: student[:student_id],
              student_name: student[:student_name],
              sequence: student[:sequence],
              frequency: frequencies_by_classroom[:students].detect do |frequency_by_student|
                if frequency_by_student[:student_id] == student[:student_id]
                  frequency_by_student[:percentage_frequency]
                end
              end
            }
          end
        }
      }
    end.compact.reduce(&:merge)
  end

  private

  def query_daily_frequencies
    @daily_frequencies_by_classroom ||= DailyFrequencyQuery.call(
      classroom_id: classrooms.pluck(:id),
      period: period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    ).order(:classroom_id).group_by(&:classroom_id)
  end

  def calculate_percentage_of_presence
    daily_frequencies_not_found if query_daily_frequencies.blank?

    query_daily_frequencies.map do |classroom_id, daily_frequencies|
      daily_frequency_students = daily_frequencies.flat_map(&:students).group_by(&:student_id)
      {
        classroom: classroom_id,
        students: daily_frequency_students.map do |key, daily_frequency_student|
          total_daily_frequency_students = daily_frequency_student.count.to_f
          total_presence = daily_frequency_student.map { |dfs| dfs if dfs.present }.compact.count.to_f
          percentage_frequency = ((total_presence / total_daily_frequency_students) * 100).round(2)

          {
            student_id: daily_frequency_student.first.student_id,
            percentage_frequency: percentage_frequency
          }
        end
      }
    end
  end

  def daily_frequencies_not_found
    raise DailyFrequenciesNotFoundError, "Não foram encontradas frequencias nessa turma e nesse periodo"
  end
end
