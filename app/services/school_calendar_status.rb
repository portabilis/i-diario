class SchoolCalendarStatus
  def initialize(api_configuration, unity_api_code, year)
    @api_configuration = api_configuration
    @unity_api_code = unity_api_code
    @year = year
  end

  def year_closed_in_ieducar?
    api = IeducarApi::SchoolCalendars.new(@api_configuration.to_api)
    response = api.fetch(escola: @unity_api_code, classroom_steps: false)
    school_calendar_data = response['escolas'].find { |e| e['ano'].to_i == @year }

    return false if school_calendar_data.nil?

    school_calendar_data['ano_em_aberto'] == false
  rescue StandardError => error
    Honeybadger.notify(error)
  end
end