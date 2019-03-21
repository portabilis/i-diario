module Api
  module V2
    class StepActivityController < Api::V2::IeducarApiBaseController
      respond_to :json

      def check
        step_number = params[:step_number].to_i

        has_activity = if params[:unity_id].present?
                         @unity = Unity.find_by!(api_code: params[:unity_id])

                         check_by_unity(@unity.id, step_number)
                       else
                         @classroom = Classroom.find_by!(api_code: params[:classroom_id])

                         check_by_classroom(@classroom.id, step_number)
                       end

        render json: has_activity
      end

      private

      def check_by_unity(unity_id, step_number)
        activity_checker = SchoolCalendarStepActivity.new(unity_id, step_number)
        activity_checker.any_activity?
      end

      def check_by_classroom(classroom_id, step_number)
        activity_checker = SchoolCalendarClassroomStepActivity.new(classroom_id, step_number)
        activity_checker.any_activity?
      end
    end
  end
end
