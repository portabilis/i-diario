module Api
  module V2
    class StudentActivityController < Api::V2::BaseController
      respond_to :json

      def check
        student_id = Student.find_by(api_code: params[:cod_aluno])&.id
        departure_date = params[:data_saida]
        
        raise ArgumentError if student_id.blank? || departure_date.blank?

        render json: activity?(student_id, departure_date)
      end

      private

      def activity?(student_id, departure_date)
        activity_checker = ActivityAfterDepartureDate.new(student_id, departure_date)
        activity_checker.has_activities
      end
    end
  end
end
