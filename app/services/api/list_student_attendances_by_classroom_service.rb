module Api
  class ListStudentAttendancesByClassroomService
    attr_accessor :classroom_api_code, :start_at, :end_at, :year, :student_api_code

    def initialize(classroom_api_code, start_at, end_at, year, student_api_code)
      @classroom_api_code = classroom_api_code
      @start_at = start_at
      @end_at = end_at
      @year = year
      @student_api_code = student_api_code
    end

    def self.call(classroom_api_code, start_at, end_at, year, student_api_code)
      new(classroom_api_code, start_at, end_at, year, student_api_code).call
    end

    def call
      query_classroom
    end

    private

    def query_classroom
      @classroom = Classroom
        .includes(classrooms_grades: { grade: :course })
        .find_by(api_code: classroom_api_code)
        .by_year(year)
        .ordered
    end
  end
end
