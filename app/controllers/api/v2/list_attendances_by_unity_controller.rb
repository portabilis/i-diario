module Api
  module V2
    class ListAttendancesByUnityController < Api::V2::BaseController
      respond_to :json

      def index
        unity = Unity.find_by(api_code: params[:unity])
        start_at = params[:start_at]
        end_at = params[:end_at]
        year = params[:year]

        raise ArgumentError if unity.blank?

        render json: compile_attendances(unity, start_at, end_at, year)
      end

      private

      def compile_attendances(unity, start_at, end_at, year)
        classrooms = Classroom
          .includes(classrooms_grades: { grade: :course })
          .by_unity(unity.id)
          .by_year(year)
          .ordered

        query_student_enrollment_classrooms = StudentEnrollmentClassroom
          .by_classroom(classrooms.pluck(:id))
          .by_date_range(start_at, end_at)
          .group('classroom_code')
          .count

        query_daily_frequencies = DailyFrequency
          .by_classroom_id(classrooms.pluck(:id))
          .by_frequency_date_between(start_at, end_at)
          .joins(:classroom, :students)
          .group('classrooms.api_code, frequency_date')
          .select("
            COUNT(daily_frequency_students.id) AS count,
            classrooms.api_code AS classroom_api_code,
            frequency_date AS frequency_date
          ")

        daily_frequencies_array = JSON.parse(query_daily_frequencies.to_json)

        frequencies_by_classrooms = daily_frequencies_array.each_with_object({}) do |record, hash|
          classroom_api_code = record['classroom_api_code']
          frequency_date = record['frequency_date']
          count = record['count']

          hash[classroom_api_code] ||= {}
          hash[classroom_api_code][frequency_date] = count
        end

        result = classrooms.map do |classroom|
          classroom_api_code = classroom.api_code
          classroom_name = classroom.description
          classroom_max_students = classroom.max_students
          enrollments_by_classroom_count = query_student_enrollment_classrooms[classroom_api_code] ||= 0
          frequencies = frequencies_by_classrooms[classroom_api_code] || {}

          grades = classroom.classrooms_grades.map do |classroom_grade|
            {
              id: classroom_grade.grade_id,
              name: classroom_grade.grade.description,
              course_id: classroom_grade.grade.course_id,
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
    end
  end
end
