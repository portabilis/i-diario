module Api
  module V2
    class StudentClassroomAttendancesController < Api::V2::BaseController
      respond_to :json
      def index
        required_params = %i[classroom_id start_at end_at year student_ids]
        missing_params = validate_required_params(required_params)

        return if missing_params
        classroom_api_code = params[:classroom_id]
        start_at = params[:start_at]
        end_at = params[:end_at]
        year = params[:year]
        students_api_code = params[:student_ids]

        render json: ListStudentAttendancesByClassroomService.call(
                      classroom_api_code, start_at, end_at, year, students_api_code
                    )
      end

      def validate_required_params(required_params)
        missing_params = required_params.select { |param| params[param].blank? }

        return false unless missing_params.any?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing_params.join(', ')}" }, status: :unprocessable_entity
      end
    end
  end
end
