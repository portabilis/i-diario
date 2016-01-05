class CurrentSchoolCalendarFetcher
  def initialize(unity)
    @unity = unity
  end

  def fetch
    SchoolCalendar.find_by(year: current_school_year, unity: @unity)
  end

  private

  def current_school_year
    current_school_year_fetcher.fetch
  end

  def current_school_year_fetcher
    @current_school_year_fetcher ||= CurrentSchoolYearFetcher.new(@unity)
  end
end
