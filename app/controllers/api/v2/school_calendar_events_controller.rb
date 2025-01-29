module Api
  module V2
    class SchoolCalendarEventsController < Api::V2::BaseController
      has_scope :page, default: 1
      has_scope :per, default: 10

      respond_to :json

      def index
        required_params = [:unity_id, :year]
        missing_params = validate_required_params(required_params)

        return if missing_params

        service = SchoolCalendarEventsService.call(
          params[:unity_id], params[:year], params[:start_date], params[:end_date], params
        )

        return render json: { error: service[:error] }, status: service[:status] if service[:error]

        render json: build_response(service)
      end

      private

      def validate_required_params(required_params)
        missing_params = required_params.select { |param| params[param].blank? }

        return false unless missing_params.any?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing_params.join(', ')}" },
               status: :unprocessable_entity
      end

      def build_response(service)
        {
          escola: service[:unity].name,
          ano: service[:year],
          eventos: service[:events],
          paginacao: service[:pagination]
        }
      end
    end
  end
end
