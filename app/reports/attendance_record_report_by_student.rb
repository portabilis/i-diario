class AttendanceRecordReportByStudent < BaseReport
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
    @classrooms = classrooms
    @enrollment_classrooms_list = enrollment_classrooms_list
    @period = period
    @start_at = start_at
    @end_at = end_at
  end

  def call
    classrooms.map do |classroom|
      students = enrollment_classrooms_list.select{ |student| student[:classroom_id].eql?(classroom.id) }
      frequencies_by_classroom = calculate_percentage_of_presence.select do |student|
        student[:classroom].eql?(classroom.id)
      end.first

      next if frequencies_by_classroom.blank?
      next if students.empty?

      {
        classroom.id => {
          classroom_name: classroom.description,
          grade_name: classroom.grades.first.description,
          students: students.map do |student|
            {
              student_id: student[:student_id],
              student_name: student[:student_name],
              sequence: student[:sequence],
              frequency: frequencies_by_classroom[:students].select do |frequency_by_student|
                frequency_by_student[:percentage_frequency] if frequency_by_student[:student_id] == student[:student_id]
              end.first
            }
          end
        }
      }
    end.compact.reduce(&:merge)
  end

  private

  def query_daily_frequencies
    @daily_frequencies_by_classroom ||= DailyFrequencyQuery.call(
      classroom_id: classrooms.map(&:id),
      period: period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    ).order(:classroom_id).group_by(&:classroom_id)
  end

  def calculate_percentage_of_presence
    daily_frequencies = query_daily_frequencies

    return if daily_frequencies.blank?

    daily_frequencies.map do |classroom_id, daily_frequencies|
      {
        classroom: classroom_id,
        students: daily_frequencies.flat_map do |daily_frequency|
          daily_frequency.students
        end.group_by(&:student_id).map do |key, daily_frequency_student|
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
end
