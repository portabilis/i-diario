module Api
  module V2
    class SchoolCalendarEventsController < Api::V2::BaseController
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

        render json: build_response(unity, year, events)
      end

      private

      def validate_required_params(required_params)
        missing_params = required_params.select { |param| params[param].blank? }

        return false unless missing_params.any?

        render json: { error: "Os seguintes parâmetros são obrigatórios: #{missing_params.join(', ')}" },
               status: :unprocessable_entity
      end

      def build_response(unity, year, events)
        {
          escola: unity.name,
          ano: year,
          eventos: events.map do |event|
            {
              descricao: event.description,
              tipo_evento: event.event_type,
              periodo: {
                inicio: event.start_date,
                fim: event.end_date
              }
            }
          end
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
          return [nil, nil]
        end

        events
      end
    end
  end
end
