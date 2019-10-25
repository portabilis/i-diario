module Api
  module V2
    class ClassroomStudentsController < Api::V2::BaseController
      respond_to :json

      def index
        student_list = fetch_students

        render json: student_list
      end

      def fetch_students
        return [] unless school_calendar

        discipline_id = params[:discipline_id]
        frequency_date = params[:frequency_date] || Time.zone.today
        step_number = step_number(frequency_date)

        @student_enrollments = StudentEnrollment.includes(:student)
                                                .by_classroom(params[:classroom_id])
                                                .by_discipline(params[:discipline_id])
                                                .by_date(frequency_date)
                                                .exclude_exempted_disciplines(discipline_id, step_number)
                                                .active
                                                .ordered

        @student_enrollments = @student_enrollments.by_period(teacher_period) if params[:teacher_id].present?
        @student_enrollments
      end

      private

      def teacher_period
        @teacher_period ||= TeacherPeriodFetcher.new(
          params[:teacher_id],
          params[:classroom_id],
          params[:discipline_id]
        ).teacher_period
      end

      def step_number(frequency_date)
        school_calendar.step(frequency_date) || 0
      end

      def school_calendar
        classroom = Classroom.find(params[:classroom_id])

        @school_calendar ||= CurrentSchoolCalendarFetcher.new(
          classroom.unity,
          classroom
        ).fetch
      end
    end
  end
end
