class SchoolCalendarClassroomQuery
  def initialize(unity, classroom)
    @unity = unity
    @classroom = classroom
  end

  def school_calendar
    SchoolCalendar.by_unity_id(unity)
                  .by_year(classroom.year)
                  .ordered
                  .first
  end

  private

  attr_accessor :unity, :classroom
end
