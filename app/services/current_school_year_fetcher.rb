class CurrentSchoolYearFetcher
  def initialize(unity, classroom = nil)
    @unity = unity
    @classroom = classroom
  end

  def fetch
    current_school_calendar.year if current_school_calendar
  end

  private

  def current_school_calendar
    @current_school_calendar ||= CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
  end

  attr_accessor :unity, :classroom
end
