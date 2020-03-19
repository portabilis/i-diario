class YearsFromUnityFetcher
  def initialize(unity_id, only_opened_years = nil)
    @unity_id = unity_id
    @only_opened_years = only_opened_years
  end

  def fetch
    school_calendars = SchoolCalendar.by_unity_id(@unity_id)
    school_calendars = school_calendars.only_opened_years if @only_opened_years
    school_calendars.ordered.map(&:year)
  end
end
