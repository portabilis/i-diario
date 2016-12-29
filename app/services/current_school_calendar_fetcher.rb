class CurrentSchoolCalendarFetcher
  def initialize(unity)
    @unity = unity
  end

  def fetch
    SchoolCalendar.by_unity_id(@unity)
      .by_school_day(Time.zone.today)
      .first
  end
end
