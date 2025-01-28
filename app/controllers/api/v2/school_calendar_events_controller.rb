module Api
  module V2
    class SchoolCalendarEventsController < Api::V2::BaseController
      respond_to :json

      def index
        required_params = [:unity_id, :year]
        missing_params = validate_required_params(required_params)

        return if missing_params

        unity_id = params[:unity_id]
        year = params[:year]

        unity = Unity.find_by(id: unity_id)
        return render json: { error: "Unidade escolar não encontrada." }, status: :not_found unless unity

        school_calendar_ids, events = validate_calendar_and_events(unity_id, year)
        return if school_calendar_ids.nil? || events.nil?

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

      def validate_calendar_and_events(unity_id, year)
        school_calendar_ids = SchoolCalendar.where(unity_id: unity_id, year: year).pluck(:id)

        if school_calendar_ids.empty?
          render json: { message: "Nenhum calendário letivo encontrado para a unidade e ano especificados." },
                 status: :not_found
          return [nil, nil]
        end

        events = SchoolCalendarEvent.where(school_calendar_id: school_calendar_ids)

        if events.empty?
          render json: { message: "Nenhum evento encontrado para os calendários letivos da unidade e ano especificados." },
                 status: :not_found
          return [nil, nil]
        end

        [school_calendar_ids, events]
      end
    end
  end
end
