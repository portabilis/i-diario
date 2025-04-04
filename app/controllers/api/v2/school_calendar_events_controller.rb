module Api
  module V2
    class SchoolCalendarEventsController < Api::V2::BaseController
      has_scope :page, default: 1
      has_scope :per, default: 10

      before_action :ensure_required_params, only: :index

      def index
        service_response = SchoolCalendarEventsService.call(
          event_params[:unity_id],
          event_params[:year],
          event_params[:start_date],
          event_params[:end_date],
          event_params
        )

        if service_response[:error].present?
          render json: { error: service_response[:error] }, status: service_response[:status]
        else
          render json: build_response(service_response)
        end
      end

      private

      def event_params
        params.permit(:unity_id, :year, :start_date, :end_date, :page, :per)
      end

      def ensure_required_params
        required = [:unity_id, :year]
        missing  = required.select { |param| event_params[param].blank? }
        return if missing.empty?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing.join(', ')}" },
               status: :unprocessable_entity
      end

      def build_response(service_response)
        pagination = service_response[:pagination]

        {
          data: service_response[:events],
          meta: {
            current_page: pagination[:current_page],
            from:         pagination[:from],
            last_page:    pagination[:last_page],
            per_page:     pagination[:per_page],
            to:           pagination[:to],
            total:        pagination[:total]
          }
        }
      end
    end
  end
end
