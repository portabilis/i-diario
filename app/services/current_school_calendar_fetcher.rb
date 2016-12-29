class CurrentSchoolCalendarFetcher
  def initialize(unity)
    @unity = unity
  end

  def fetch
    SchoolCalendar.by_unity_id(@unity)
      .first
  end
end
