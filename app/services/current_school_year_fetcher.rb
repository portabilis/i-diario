class CurrentSchoolYearFetcher
  def initialize(unity)
    @unity = unity
  end

  def fetch
    current_school_calendar.year if current_school_calendar
  end

  private

  def current_school_calendar
    @current_school_calendar ||= current_school_calendar_fetcher.fetch
  end

  def current_school_calendar_fetcher
    @current_school_calendar_fetcher ||= CurrentSchoolCalendarFetcher.new(@unity)
  end
end
