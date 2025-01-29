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

        unity_api_code = params[:unity_id]
        year = params[:year]
        start_date = params[:start_date]
        end_date = params[:end_date]

        unity = Unity.find_by(api_code: unity_api_code)
        return render json: { error: 'Unidade escolar não encontrada.' }, status: :not_found unless unity

        events = validate_calendar_and_events(unity.id, year, start_date, end_date)
        return if events.nil?

        paginated_events = apply_scopes(events)

        render json: build_paginated_response(unity, year, paginated_events)
      end

      private

      def validate_required_params(required_params)
        missing_params = required_params.select { |param| params[param].blank? }

        return false unless missing_params.any?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing_params.join(', ')}" },
               status: :unprocessable_entity
      end

      def build_paginated_response(unity, year, paginated_events)
        {
          escola: unity.name,
          ano: year,
          eventos: paginated_events.map do |event|
            build_event_response(event)
          end,
          paginacao: build_pagination_response(paginated_events)
        }
      end

      def build_event_response(event)
        {
          descricao: event.description,
          tipo_evento: event.event_type,
          periodo: {
            inicio: event.start_date,
            fim: event.end_date
          }
        }
      end

      def build_pagination_response(paginated_events)
        {
          pagina_atual: paginated_events.current_page,
          total_paginas: paginated_events.total_pages,
          total_eventos: paginated_events.total_count,
          por_pagina: paginated_events.limit_value
        }
      end

      def validate_calendar_and_events(unity_id, year, start_date = nil, end_date = nil)
        events = SchoolCalendarEvent.joins(:school_calendar)
                                    .where(school_calendars: { unity_id: unity_id, year: year })

        if start_date.present? && end_date.present?
          events = events.where('start_date >= ? AND end_date <= ?', start_date, end_date)
        end

        if events.empty?
          render json: { message: 'Nenhum evento encontrado para os calendários letivos da unidade e ano especificados.' },
                 status: :not_found
          return nil
        end

        events
      end
    end
  end
end
