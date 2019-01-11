class SchoolCalendarQuery
  def initialize(unity, year = nil)
    @unity = unity
    @year = year || Time.current.year
  end

  def school_calendar
    @school_calendar = SchoolCalendar.by_unity_id(unity)
    @school_calendar.by_year(year) if year.present?

    @school_calendar.ordered.first
  end

  private

  attr_accessor :unity, :year
end
