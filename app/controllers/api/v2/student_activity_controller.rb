module Api
  module V2
    class StudentActivityController < Api::V2::BaseController
      respond_to :json

      def check
        student_id = Student.find_by(api_code: params[:cod_aluno])&.id
        exit_date = params[:data_saida]
        
        raise ArgumentError if student_id.blank? || exit_date.blank?

        render json: activity(student_id, exit_date)
      end

      private

      def activity(student_id, exit_date)
        activity_checker = StudentActivityAfterDate.new(student_id, exit_date)
        activity_checker.student_activities
      end
    end
  end
end
