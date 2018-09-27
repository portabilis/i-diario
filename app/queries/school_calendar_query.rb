class SchoolCalendarQuery
  def initialize(unity, year = nil)
    @unity = unity
    @year = year || Time.current.year
  end

  def school_calendar
    SchoolCalendar.by_unity_id(unity)
    .by_year(year)
    .first
  end

  private

  attr_accessor :unity, :year
end
