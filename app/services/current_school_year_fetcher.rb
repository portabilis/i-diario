class CurrentSchoolYearFetcher
  def initialize(unity)
    @unity = unity
  end

  def fetch
    current_school_calendar.year if current_school_calendar
  end

  private

  def current_school_calendar
    @current_school_calendar ||= CurrentSchoolCalendarFetcher.new(unity, nil).fetch
  end

  attr_accessor :unity
end
