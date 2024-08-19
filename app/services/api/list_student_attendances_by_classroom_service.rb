module Api
  class ListStudentAttendancesByClassroomService
    attr_accessor :classroom_api_code, :start_at, :end_at, :year, :students_api_code

    def initialize(classroom_api_code, start_at, end_at, year, students_api_code)
      @classroom_api_code = classroom_api_code
      @start_at = start_at
      @end_at = end_at
      @year = year
      @students_api_code = students_api_code
    end

    def self.call(classroom_api_code, start_at, end_at, year, students_api_code)
      new(classroom_api_code, start_at, end_at, year, students_api_code).call
    end

    def call
      classroom = query_classroom
      frequencies_by_classrooms = process_daily_frequencies_by_classroom(classroom)

      build_classroom_information(classroom, frequencies_by_classrooms)
    end

    private

    def query_classroom
      Classroom.includes(classrooms_grades: { grade: :course }).find_by(year: year, api_code: classroom_api_code)
    end

    def process_daily_frequencies_by_classroom(classroom)
      student_ids = Student.where(api_code: students_api_code).pluck(:id)
      daily_frequencies = query_daily_frequencies(classroom.id, student_ids)

      format_frequencies(daily_frequencies)
    end

    def query_daily_frequencies(classroom_id, student_ids)
      DailyFrequency
        .by_classroom_id(classroom_id)
        .by_frequency_date_between(start_at, end_at)
        .joins(:classroom, students: :student)
        .where(daily_frequency_students: { student_id: student_ids })
        .group('classrooms.api_code, students.api_code, students.name')
        .select("
          students.api_code AS student_api_code,
          students.name AS student_name,
          SUM(daily_frequency_students.present::int) AS presences,
          SUM((NOT daily_frequency_students.present)::int) AS absences,
          classrooms.api_code AS classroom_api_code
        ")
    end

    def format_frequencies(daily_frequencies)
      daily_frequencies.each_with_object({}) do |record, hash|
        classroom_code = record['classroom_api_code']
        student_code = record['student_api_code']

        hash[classroom_api_code] ||= {}
        hash[classroom_api_code][student_code] ||= {
          name: record['student_name'],
          presences: record['presences'],
          absences: record['absences']
        }
      end
    end

    def build_classroom_information(classroom, daily_frequencies)
      {
        classroom_id: classroom.api_code,
        classroom_name: classroom.description,
        grades: build_grades(classroom),
        attendances_by_student: daily_frequencies[classroom_api_code] || {}
      }
    end

    def build_grades(classroom)
      classroom.classrooms_grades.map do |classroom_grade|
        {
          id: classroom_grade.grade_id,
          name: classroom_grade.grade.description,
          course_id: classroom_grade.grade.course_id,
          course_name: classroom_grade.grade.course.description
        }
      end
    end
  end
end
