class SchoolCalenderEventFetcher
  def initialize(resource, options = {})
    @resource = resource
  end

  def uniqueness_start_at_and_end_at?
    attributes = {
      school_calendar_id: @resource.school_calendar_id, coverage: @resource.coverage,
      start_date: @resource.start_date, end_date: @resource.end_date,
      grade_id: @resource.grade_id, course_id: @resource.course_id , discipline_id: @resource.discipline_id , classroom_id: @resource.classroom_id
    }
    events = SchoolCalendarEvent.where(attributes)
    events = events.where("(start_date <= ?) and (end_date >= ?)", @resource.end_date, @resource.start_date)
    events = events.where("id != :id", id: @resource.id) if @resource.id
    events.any?
  end

end
