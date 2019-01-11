class CurrentSchoolCalendarFetcher
  def initialize(unity, classroom, year = nil)
    @unity = unity
    @classroom = classroom
    @year = year
  end

  def fetch
    if classroom_steps?
      SchoolCalendarClassroomQuery.new(unity, classroom).school_calendar
    else
      SchoolCalendarQuery.new(unity, year).school_calendar
    end
  end

  private

  attr_accessor :unity, :classroom, :year

  def classroom_steps?
    return false if classroom.nil?

    classroom.calendar
  end
end
