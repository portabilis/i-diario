class SchoolCalendarClassroomQuery
  def initialize(unity, classroom)
    @unity = unity
    @classroom = classroom
  end

  def school_calendar
    SchoolCalendar.by_unity_id(unity)
    .by_school_day_classroom_steps(Time.zone.today, classroom)
    .first
  end

  private

  attr_accessor :unity, :classroom
end
