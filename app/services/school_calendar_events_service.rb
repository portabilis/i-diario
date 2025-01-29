class SchoolCalendarEventsService
  def self.call(unity_api_code, year, start_date, end_date, params)
    new(unity_api_code, year, start_date, end_date, params).perform
  end

  def initialize(unity_api_code, year, start_date, end_date, params)
    @unity_api_code = unity_api_code
    @year = year
    @start_date = start_date
    @end_date = end_date
    @params = params
  end

  def perform
    unity = Unity.find_by(api_code: @unity_api_code)
    return { error: 'Unidade escolar não encontrada.', status: :not_found } unless unity

    events = fetch_events(unity.id)
    return { error: 'Nenhum evento encontrado.', status: :not_found } if events.empty?

    paginated_events = events.page(@params[:page]).per(@params[:per])

    {
      unity: unity,
      year: @year,
      events: format_events(paginated_events),
      pagination: build_pagination_response(paginated_events)
    }
  end

  private

  def fetch_events(unity_id)
    events = SchoolCalendarEvent.joins(:school_calendar)
                                .where(school_calendars: { unity_id: unity_id, year: @year })

    if @start_date.present? && @end_date.present?
      events = events.where('start_date >= ? AND end_date <= ?', @start_date, @end_date)
    end

    events
  end

  def format_events(events)
    events.map do |event|
      {
        descricao: event.description,
        tipo_evento: event.event_type,
        periodo: {
          inicio: event.start_date,
          fim: event.end_date
        }
      }
    end
  end

  def build_pagination_response(paginated_events)
    {
      current_page: paginated_events.current_page,
      from: paginated_events.offset_value + 1,
      last_page: paginated_events.total_pages,
      per_page: paginated_events.limit_value,
      to: [paginated_events.offset_value + paginated_events.limit_value, paginated_events.total_count].min,
      total: paginated_events.total_count
    }
  end
end
