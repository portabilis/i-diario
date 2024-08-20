module Api
  class ClassroomAttendanceService

    attr_accessor :classrooms_api_code, :start_at, :end_at, :year

    def initialize(classrooms_api_code, start_at, end_at, year)
      @classrooms_api_code = classrooms_api_code
      @start_at = start_at
      @end_at = end_at
      @year = year
    end

    def self.call(classrooms_api_code, start_at, end_at, year)
      new(classrooms_api_code, start_at, end_at, year).call
    end

    def call
      query_classrooms
      student_enrollment_classrooms = process_student_enrollment_classrooms
      frequencies_by_classrooms = process_daily_frequencies

      build_classroom_information(student_enrollment_classrooms, frequencies_by_classrooms)
    end

    private

    def query_classrooms
      @classrooms = Classroom
        .includes(classrooms_grades: { grade: :course })
        .where(api_code: classrooms_api_code.values)
        .by_year(year)
        .ordered
    end

    def process_student_enrollment_classrooms
      enrollments = query_student_enrollment_classrooms
      list_student_enrollment_classrooms_by_day(enrollments)
    end

    def process_daily_frequencies
      daily_frequencies = JSON.parse(query_daily_frequencies.to_json)
      daily_frequencies_array(daily_frequencies)
    end

    def build_classroom_information(student_enrollment_classrooms, frequencies_by_classrooms)
      @classrooms.map do |classroom|
        classroom_api_code = classroom.api_code
        classroom_name = classroom.description
        classroom_max_students = classroom.max_students
        enrollments_by_classroom_count = student_enrollment_classrooms[classroom_api_code] ||= 0
        frequencies = frequencies_by_classrooms[classroom_api_code] || {}

        attendance_and_enrollments = attendance_and_enrollment_data(frequencies,enrollments_by_classroom_count)
        grades = build_grade_hashes(classroom)

        {
          classroom_id: classroom_api_code,
          classroom_name: classroom_name,
          classroom_max_students: classroom_max_students,
          grades: grades,
          attendance_and_enrollments: attendance_and_enrollments
        }
      end
    end

    def query_student_enrollment_classrooms
      StudentEnrollmentClassroom
        .by_classroom(@classrooms.pluck(:id))
        .by_date_range(start_at, end_at)
        .group_by(&:classroom_code)
    end

    def list_student_enrollment_classrooms_by_day(student_enrollment_classrooms)
      enrollment_counts = {}
      range_dates = (start_at..end_at).to_a

      student_enrollment_classrooms.each do |classroom_code, enrollments|
        enrollment_counts[classroom_code] ||= {}

        range_dates.each do |day|
          enrollment_counts[classroom_code][day] ||= 0

          enrollments.each do |enrollment|
            if enrollment.joined_at <= day && (enrollment.left_at.blank? || enrollment.left_at >= day)
              enrollment_counts[classroom_code][day] += 1
            end
          end
        end
      end

      enrollment_counts
    end

    def query_daily_frequencies
      DailyFrequency
        .by_classroom_id(@classrooms.pluck(:id))
        .by_frequency_date_between(start_at, end_at)
        .joins(:classroom, :students)
        .group('classrooms.api_code, frequency_date')
        .select("
          COUNT(DISTINCT CONCAT(daily_frequency_students.student_id, '-', frequency_date)) AS count,
          SUM(daily_frequency_students.present::int) AS presences,
          classrooms.api_code AS classroom_api_code,
          frequency_date AS frequency_date
        ")
    end

    def daily_frequencies_array(daily_frequencies_array)
      daily_frequencies_array.each_with_object({}) do |record, hash|
        classroom_api_code = record['classroom_api_code']
        frequency_date = record['frequency_date']
        count = record['presences']

        hash[classroom_api_code] ||= {}
        hash[classroom_api_code][frequency_date] = count
      end
    end

    def build_grade_hashes(classroom)
      classroom.classrooms_grades.map do |classroom_grade|
        {
          id: classroom_grade.grade_id,
          name: classroom_grade.grade.description,
          course_id: classroom_grade.grade.course_id,
          course_name: classroom_grade.grade.course.description
        }
      end
    end

    def attendance_and_enrollment_data(frequencies, enrollments_by_classroom_count)
      frequencies.map do |date_frequencies, frequency_count|
        {
          date_frequencies => {
            frequencies: frequency_count,
            enrollments: enrollments_by_classroom_count[date_frequencies] || 0
          }
        }
      end.reduce(:merge)
    end
  end
end
