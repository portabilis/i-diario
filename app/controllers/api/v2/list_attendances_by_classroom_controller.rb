module Api
  module V2
    class ListAttendancesByClassroomController < Api::V2::BaseController
      respond_to :json

      def index
        required_params = %i[classrooms start_at end_at year]
        missing_params = validate_required_params(required_params)

        return if missing_params

        classrooms_api_code = params[:classrooms]
        start_at = params[:start_at]
        end_at = params[:end_at]
        year = params[:year]

        render json: ClassroomAttendanceService.call(classrooms_api_code, start_at, end_at, year)
      end

      def validate_required_params(required_params)
        missing_params = required_params.select { |param| params[param].blank? }

        return false unless missing_params.any?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing_params.join(', ')}" }, status: :unprocessable_entity
      end
    end
  end
end
