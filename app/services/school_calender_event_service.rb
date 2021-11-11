class SchoolCalenderEventService
  def initialize(resource, options = {})
    @resource = resource
  end

  def uniqueness_start_at_and_end_at
    date_at_result(search_event)
  end

  private

  def date_at_result(event)
    result = { start_date_at: false, end_date_at: false }
    result.merge!({ start_date_at: @resource.start_date.to_date.between?(event.start_date, event.end_date) }) if event
    result.merge!({ end_date_at: @resource.end_date.to_date.between?(event.start_date, event.end_date) }) if event
    if result[:start_date_at].eql?(false) && result[:end_date_at].eql?(false)
      result.merge!({ start_date_at: event.start_date.to_date.between?(@resource.start_date, @resource.end_date) }) if event
      result.merge!({ end_date_at: event.end_date.to_date.between?(@resource.start_date, @resource.end_date) }) if event
    end
    result
  end

  def search_event
    attributes = {
      school_calendar_id: @resource.school_calendar_id,
      coverage: @resource.coverage,
      grade_id: @resource.grade_id,
      course_id: @resource.course_id,
      discipline_id: @resource.discipline_id,
      classroom_id: @resource.classroom_id
    }
    events = SchoolCalendarEvent.where(attributes)
    events = events.where("(? <= end_date and ? >= start_date)", @resource.start_date, @resource.end_date)
    events = events.where("id != :id", id: @resource.id) if @resource.persisted?
    events.last
  end

end
