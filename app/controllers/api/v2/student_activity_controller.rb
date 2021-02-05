module Api
  module V2
    class StudentActivityController < Api::V2::BaseController
      respond_to :json

      def check
        departure_date = params[:data_saida]
        student = Student.find_by(id: params[:cod_aluno])

        render json: activity?(student.api_code, departure_date)
      end

      private

      def activity?(student_id, departure_date)
        activity_checker = ActivityAfterDepartureDate.new(student_id, departure_date)
        activity_checker.has_activities
      end
    end
  end
end
