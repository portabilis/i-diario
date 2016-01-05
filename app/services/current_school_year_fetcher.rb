class CurrentSchoolYearFetcher
  def initialize(unity)
    @unity = unity
  end

  def fetch
    @unity.current_school_year
  end
end
