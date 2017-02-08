class CurrentSchoolCalendarFetcher
  def initialize(unity, classroom)
    @unity = unity
    @classroom = classroom
  end

  def fetch
    if has_classroom_steps?(@classroom)
      SchoolCalendar.by_unity_id(@unity)
      .by_school_day_classroom_steps(Time.zone.today, @classroom)
      .first
    else
      SchoolCalendar.by_unity_id(@unity)
      .by_school_day(Time.zone.today)
      .first
    end
  end

  private

  def has_classroom_steps?(classroom)
    return false if classroom.nil?
    classroom = Classroom.find(classroom)
    classroom.calendar
  end
end
