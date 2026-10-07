module Api
  module V2
    class ScheduledEvaluationsController < Api::V2::BaseController
      respond_to :json

      def index
        return if missing_required_params?

        render json: ListScheduledEvaluationsByClassroomService.call(
          classroom_api_code: params[:classroom_id],
          year: params[:year],
          step_number: params[:step_number],
          discipline_api_code: params[:discipline_id],
          after_date: params[:after_date]
        )
      end

      private

      def missing_required_params?
        required_params = %i[classroom_id year]
        missing_params = required_params.select { |param| params[param].blank? }

        return false unless missing_params.any?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing_params.join(', ')}" },
               status: :unprocessable_entity
      end
    end
  end
end
