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
    end

    private

    def query_classroom
      Classroom
        .includes(classrooms_grades: { grade: :course })
        .by_year(year)
        .find_by(api_code: classroom_api_code)
    end

    def process_daily_frequencies_by_classroom(classroom)
    end
  end
end
