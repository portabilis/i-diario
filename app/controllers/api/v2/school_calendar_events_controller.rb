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
        pagination = service[:pagination]

        {
          data: service[:events],
          links: {
            first: pagination_link(1, pagination[:per_page], pagination[:last_page]),
            last: pagination_link(pagination[:last_page], pagination[:per_page], pagination[:last_page]),
            prev: if pagination[:current_page] > 1
                    pagination_link(pagination[:current_page] - 1, pagination[:per_page], pagination[:last_page])
                  end,
            next: if pagination[:current_page] < pagination[:last_page]
                    pagination_link(pagination[:current_page] + 1, pagination[:per_page], pagination[:last_page])
                  end
          },
          meta: {
            current_page: pagination[:current_page],
            from: pagination[:from],
            last_page: pagination[:last_page],
            per_page: pagination[:per_page],
            to: pagination[:to],
            total: pagination[:total]
          }
        }
      end

      def pagination_link(page, per_page, last_page)
        return nil if page < 1 || page > last_page

        "events?page=#{page}&per=#{per_page}"
      end
    end
  end
end
