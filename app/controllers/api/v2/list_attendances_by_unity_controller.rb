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

        classrooms = Classroom.includes(classrooms_grades: { grade: :course })
                              .by_unity(unity.id)
                              .by_year(year)
                              .ordered
                              .distinct

        classroom_enrollments = StudentEnrollmentClassroom.includes(student_enrollment: :student)
                                                          .includes(:classrooms_grade)
                                                          .by_classroom(classrooms.map(&:id))
                                                          .by_date_range(start_at, end_at)
                                                          .group_by { |enrollment|
                                                            enrollment.classrooms_grade.classroom_id
                                                          }

        classroom_enrollments.values.flat_map do |enrollments|
          classroom_id = enrollments.first.classrooms_grade.classroom_id
          enrollments_by_classrooms[classroom_id] = enrollments.map(&:student_enrollment).uniq(&:student).count
        end

        frequencies_by_dates = DailyFrequency.includes(:students)
                                             .by_classroom_id(classrooms.map(&:id))
                                             .by_frequency_date_between(start_at, end_at)
                                             .group_by { |frequency| frequency.frequency_date }

        frequencies_by_dates.each do |date, frequencies|
          frequencies.each do |frequency|
            classroom_id = frequency.classroom_id
            frequencies_by_classrooms[classroom_id] ||= {}
            frequencies_by_classrooms[classroom_id][date] ||= []
            frequencies_by_classrooms[classroom_id][date] << frequency
          end
        end

        result = classrooms.map do |classroom|
          classroom_id = classroom.id
          classroom_name = classroom.description

          enrollments_by_classroom_count = enrollments_by_classrooms[classroom_id] ||= 0
          frequencies = frequencies_by_classrooms[classroom_id] || {}

          grades = classroom.classrooms_grades.map do |classroom_grade|
            {
              id: classroom_grade.grade_id,
              name: classroom_grade.grade.description,
              course_id: classroom_grade.grade.course_id,
              course_name: classroom_grade.grade.course.description
            }
          end
          periods = frequencies.transform_values do |daily_frequencies|
            frequency = daily_frequencies.flat_map(&:students).select{ |dfs| dfs.present == true}.size
            {
              frequency: frequency
            }
          end

          {
            classroom_id: classroom_id,
            classroom_name: classroom_name,
            enrollments: enrollments_by_classroom_count,
            grades: grades,
            periods: periods
          }
        end
      end
    end
  end
end
