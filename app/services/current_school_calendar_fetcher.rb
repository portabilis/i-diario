class CurrentSchoolCalendarFetcher
  def initialize(unity, classroom)
    @unity = unity
    @classroom = classroom
  end

  def fetch
    if has_classroom_steps?
      SchoolCalendarClassroomQuery.new(unity, classroom).school_calendar
    else
      SchoolCalendarQuery.new(unity).school_calendar
    end
  end

  private
  attr_accessor :unity, :classroom

  def has_classroom_steps?
    return false if classroom.nil?
    classroom.calendar
  end
end
