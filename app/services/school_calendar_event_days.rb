class SchoolCalendarEventDays
  def initialize(
    school_calendars,
    events,
    action_name,
    old_start_date = nil,
    old_end_date = nil,
    event_type_changed = false
  )
    @school_calendars = school_calendars
    @events = events
    @action_name = action_name
    @old_start_date = old_start_date
    @old_end_date = old_end_date
    @event_type_changed = event_type_changed
  end

  def self.update_school_days(
    school_calendars,
    events,
    action_name,
    old_start_date = nil,
    old_end_date = nil,
    event_type_changed = false
  )
    new(
      school_calendars,
      events,
      action_name,
      old_start_date,
      old_end_date,
      event_type_changed
    ).update_school_days
  end

  def update_school_days
    events_and_days = list_event_days

    events_and_days.each do |event_type, days|
      case @action_name
      when 'create'
        process_school_days(event_type, days, :create)
      when 'destroy'
        process_school_days(event_type, days, :destroy)
      when 'update'
        if @event_type_changed && event_type_includes_no_school?
          destroy_school_days(days)
        else
          update_school_days_for_event_type(event_type, days)
        end
      end
    end
  end

  private

  def list_event_days
    @events.map do |event|
      event_type = [EventTypes::NO_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY].include?(event.event_type)
      [event_type, (event.start_date..event.end_date).to_a]
    end
  end

  def process_school_days(_event_type, school_days, action)
    days_to_process = []
    unities_ids = []

    @school_calendars.each do |school_calendar|
      school_days.each do |school_day|
        next unless valid_school_day?(school_calendar, school_day, action == :create)

        days_to_process << school_day
        unities_ids << school_calendar.unity_id

        SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).send(action, @events)
      end
    end

    update_daily_frequencies(unities_ids.uniq, days_to_process)
  end

  def valid_school_day?(school_calendar, school_day, creating)
    return false if creating && school_calendar.events.by_date(school_day).where.not(coverage: 'by_unity').exists?

    SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).school_day?
  end

  def update_daily_frequencies(unities_ids, days_to_process)
    coverage = @events.map(&:coverage).uniq
    classroom_ids = search_classrooms(coverage, unities_ids)

    DailyFrequency.where(
      unity_id: unities_ids,
      classroom_id: classroom_ids,
      frequency_date: days_to_process
    ).destroy_all
  end

  def search_classrooms(coverage, unities_ids)
    classroom_ids = []

    if coverage.include?('by_grade')
      grade_ids = @events.map(&:grade_id).uniq
      classroom_ids += ClassroomsGrade.where(grade_id: grade_ids).map(&:classroom_id).uniq
    end

    classroom_ids += @events.map(&:classroom_id).uniq if coverage.include?('by_classroom')
    classroom_ids += Classroom.where(unity_id: unities_ids).map(&:id).uniq if coverage.include?('by_unity')

    if coverage.include?('by_course')
      course_ids = @events.map(&:course_id).uniq
      grade_ids = Grade.where(course_id: course_ids).map(&:id).uniq
      classroom_ids += ClassroomsGrade.where(grade_id: grade_ids).map(&:classroom_id).uniq
    end

    classroom_ids
  end

  def update_school_days_for_event_type(event_type, days)
    old_days = (@old_start_date..@old_end_date).to_a

    if event_type
      process_school_days(true, days - old_days, :create)
      process_school_days(true, old_days - days, :destroy)
    else
      process_school_days(false, old_days - days, :create)
      process_school_days(false, days - old_days, :destroy)
    end
  end

  def event_type_includes_no_school?
    (@events.pluck(:event_type) & [EventTypes::NO_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY]).any?
  end
end
