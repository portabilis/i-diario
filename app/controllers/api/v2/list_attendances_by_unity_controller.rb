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
        frequencies_by_classrooms = {}
        enrollments_by_classrooms = {}

        classrooms = Classroom
          .includes(classrooms_grades: { grade: :course })
          .by_unity(unity.id)
          .by_year(year)
          .ordered

        enrollments_by_classrooms = StudentEnrollmentClassroom
          .by_classroom(classrooms.map(&:id))
          .by_date_range(start_at, end_at)
          .group('classroom_code')
          .count

        frequencies_by_dates = DailyFrequency.includes(:students)
                                             .by_classroom_id(classrooms.map(&:id))
                                             .by_frequency_date_between(start_at, end_at)
                                             .group_by { |frequency| frequency.frequency_date }

        frequencies_by_dates.each do |date, frequencies|
          frequencies.each do |frequency|
            classroom_api_code = frequency.classroom.api_code
            frequencies_by_classrooms[classroom_api_code] ||= {}
            frequencies_by_classrooms[classroom_api_code][date] ||= []
            frequencies_by_classrooms[classroom_api_code][date] << frequency
          end
        end

        result = classrooms.map do |classroom|
          classroom_api_code = classroom.api_code
          classroom_name = classroom.description

          enrollments_by_classroom_count = enrollments_by_classrooms[classroom_api_code] ||= 0
          frequencies = frequencies_by_classrooms[classroom_api_code] || {}

          grades = classroom.classrooms_grades.map do |classroom_grade|
            {
              id: classroom_grade.grade_id,
              name: classroom_grade.grade.description,
              course_id: classroom_grade.grade.course_id,
              course_name: classroom_grade.grade.course.description
            }
          end
          dates = frequencies.transform_values do |daily_frequencies|
            frequency = daily_frequencies.flat_map(&:students).select{ |dfs| dfs.present == true}.size
            {
              frequency: frequency
            }
          end

          {
            classroom_id: classroom_api_code,
            classroom_name: classroom_name,
            enrollments: enrollments_by_classroom_count,
            grades: grades,
            dates: dates
          }
        end
      end
    end
  end
end
