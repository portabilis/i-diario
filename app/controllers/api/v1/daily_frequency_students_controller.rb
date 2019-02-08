module Api
  module V1
    class DailyFrequencyStudentsController < Api::V1::BaseController
      respond_to :json

      def update
        daily_frequency_student = DailyFrequencyStudent.find(params[:id])
        daily_frequency_student.update(
          present: params[:present],
          active: true
        )

        respond_with daily_frequency_student
      end

      def current_user
        User.find(user_id)
      end

      protected

      def user_id
        @user_id ||= params[:user_id] || 1
      end
    end
  end
end
