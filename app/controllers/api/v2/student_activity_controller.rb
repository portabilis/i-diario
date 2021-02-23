module Api
  module V2
    class StudentActivityController < Api::V2::BaseController
      respond_to :json

      def check
        student_id = Student.find_by(api_code: params[:student_id])&.id
        exit_date = params[:exit_date]

        raise ArgumentError if student_id.blank? || exit_date.blank?

        render json: activity(student_id, exit_date)
      end

      private

      def activity(student_id, exit_date)
        activity_checker = StudentActivityAfterDate.new
        activity_checker.student_activities(student_id, exit_date)
      end
    end
  end
end
