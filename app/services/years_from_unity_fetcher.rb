class YearsFromUnityFetcher
  def initialize(unity_id)
    @unity_id = unity_id
  end

  def fetch
    SchoolCalendar.by_unity_id(@unity_id).ordered.map(&:year)
  end
end
