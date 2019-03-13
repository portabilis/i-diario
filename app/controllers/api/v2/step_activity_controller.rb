module Api
  module V2
    class StepActivityController < Api::V2::IeducarApiBaseController
      respond_to :json

      def check
        step_number = params[:step_number].to_i

        has_activity = if params[:unity_id].present?
                         @unity = Unity.find_by(api_code: params[:unity_id])
                         raise ActiveRecord::RecordNotFound unless @unity

                         check_by_unity(@unity.id, step_number)
                       else
                         @classroom = Classroom.find_by(api_code: params[:classroom_id])
                         raise ActiveRecord::RecordNotFound unless @classroom

                         check_by_classroom(@classroom.id, step_number)
                       end

        render json: has_activity
      end

      private

      def check_by_unity(unity_id, step_number)
        calendar_step = school_calendar_step(unity_id, step_number)

        activity_checker = SchoolCalendarStepActivity.new(unity_id, calendar_step, step_number)
        activity_checker.any_activity?
      end

      def check_by_classroom(classroom_id, step_number)
        calendar_step = school_classroom_calendar_step(step_number)

        activity_checker = SchoolCalendarClassroomStepActivity.new(classroom_id, calendar_step, step_number)
        activity_checker.any_activity?
      end

      def school_calendar_step(unity_id, step_number)
        year = CurrentSchoolYearFetcher.new(unity_id).fetch

        SchoolCalendarStep.by_unity(unity_id)
                          .by_year(year)
                          .by_step_number(step_number)
                          .first
      end

      def school_classroom_calendar_step(step_number)
        StepsFetcher.new(@classroom).step(step_number)
      end
    end
  end
end
