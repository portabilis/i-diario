class SchoolCalendarQuery
  def initialize(unity)
    @unity = unity
  end

  def school_calendar
    SchoolCalendar.by_unity_id(unity)
    .by_school_day(Time.zone.today)
    .first
  end

  private

  attr_accessor :unity
end
