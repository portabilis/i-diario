module Api
  class ClassroomAttendanceService

    attr_accessor :unity_id, :start_at, :end_at, :year

    def initialize(unity_id, start_at, end_at, year)
      @unity_id = unity_id
      @start_at = start_at
      @end_at = end_at
      @year = year
    end

    def self.call(unity_id, start_at, end_at, year)
      new(unity_id, start_at, end_at, year).call
    end

    def call
      query_classrooms
      query_student_enrollment_classrooms

      daily_frequencies_array = JSON.parse(query_daily_frequencies.to_json)
      frequencies_by_classrooms = daily_frequencies_array(daily_frequencies_array)

      @classrooms.map do |classroom|
        classroom_api_code = classroom.api_code
        classroom_name = classroom.description
        classroom_max_students = classroom.max_students
        enrollments_by_classroom_count = query_student_enrollment_classrooms[classroom_api_code] ||= 0
        frequencies = frequencies_by_classrooms[classroom_api_code] || {}

        grades = classroom.classrooms_grades.map do |classroom_grade|
          {
            id: classroom_grade.grade.api_code,
            name: classroom_grade.grade.description,
            course_id: classroom_grade.grade.course.api_code,
            course_name: classroom_grade.grade.course.description
          }
        end

        {
          classroom_id: classroom_api_code,
          classroom_name: classroom_name,
          classroom_max_students: classroom_max_students,
          enrollments: enrollments_by_classroom_count,
          grades: grades,
          dates: frequencies
        }
      end
    end

    def hash_grades(classroom)
      classroom.classrooms_grades.map do |classroom_grade|
        {
          id: classroom_grade.grade_id,
          name: classroom_grade.grade.description,
          course_id: classroom_grade.grade.course_id,
          course_name: classroom_grade.grade.course.description
        }
      end
    end

    def query_classrooms
      @classrooms = Classroom
        .includes(classrooms_grades: { grade: :course })
        .by_unity(unity_id)
        .by_year(year)
        .ordered
    end

    def query_student_enrollment_classrooms
      @student_enrollment_classrooms = StudentEnrollmentClassroom
        .by_classroom(@classrooms.pluck(:id))
        .by_date_range(start_at, end_at)
        .group('classroom_code')
        .count
    end

    def query_daily_frequencies
      query_daily_frequencies = DailyFrequency
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
        count = record['count']

        hash[classroom_api_code] ||= {}
        hash[classroom_api_code][frequency_date] = count
      end
    end
  end
end
