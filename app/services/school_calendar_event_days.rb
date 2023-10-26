class SchoolCalendarEventDays
  def initialize(
    school_calendars,
    events,
    action_name,
    old_start_date = nil,
    old_end_date = nil
  )
    @school_calendars = school_calendars
    @events = events
    @action_name = action_name
    @old_start_date = old_start_date
    @old_end_date = old_end_date
  end

  def self.update_school_days(
    school_calendars,
    events,
    action_name,
    old_start_date = nil,
    old_end_date = nil
  )
    new(
      school_calendars,
      events, action_name,
      old_start_date,
      old_end_date
    ).update_school_days
  end

  def update_school_days
    events_and_days = list_event_days

    events_and_days.each do |event_type, days|
      case @action_name
      when 'create'
        event_type ? create_school_days(days) : destroy_school_days(days)
      when 'destroy'
        event_type ? destroy_school_days(days) : create_school_days(days)
      when 'update'
        update_school_days_for_event_type(event_type, days)
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

  def create_school_days(school_days)
    days_to_destroy = []
    unities_ids = []

    @school_calendars.each do |school_calendar|
      school_days.each do |school_day|
        events_by_date = school_calendar.events.by_date(school_day)
        next if events_by_date.where.not(coverage: "by_unity").exists?
        next unless SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).school_day?

        days_to_destroy << school_day
        unities_ids << school_calendar.unity_id

        SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).create(@events)
      end
    end

    coverage = @events.map(&:coverage).uniq
    classroom_ids = search_classrooms(coverage, unities_ids.uniq)

    DailyFrequency.where(
      unity_id: unities_ids.uniq,
      classroom_id: classroom_ids,
      frequency_date: days_to_destroy
    ).destroy_all
  end

  def destroy_school_days(school_days)
    @school_calendars.each do |school_calendar|
      school_days.each do |school_day|
        next unless SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).school_day?

        SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).destroy(@events)
      end
    end
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
      create_school_days(days - old_days)
      destroy_school_days(old_days - days)
    else
      create_school_days(old_days - days)
      destroy_school_days(days - old_days)
    end
  end
end
