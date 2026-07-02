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
          process_school_days(event_type, days, :destroy)
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

        if event_type_includes_no_school?
          days_to_process << school_day
          unities_ids << school_calendar.unity_id
          next if action == :destroy
        end

        next unless valid_school_day?(school_calendar, school_day, action == :create)

        unless event_type_includes_no_school?
          days_to_process << school_day
          unities_ids << school_calendar.unity_id
        end

        unless @events.pluck(:event_type).include?(EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY)
          SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).send(action, @events)
        end
      end
    end

    if event_type_includes_no_school?
      update_daily_frequencies(unities_ids.uniq, days_to_process)
    end
  end

  def valid_school_day?(school_calendar, school_day, creating)
    return false if creating && school_calendar.events.by_date(school_day).where.not(coverage: 'by_unity').exists?

    SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).school_day?
  end

  def update_daily_frequencies(unities_ids, days_to_process)
    coverage = @events.map(&:coverage).uniq
    classroom_ids = search_classrooms(coverage, unities_ids)
    event_periods = @events.flat_map(&:periods).compact.uniq

    daily_frequencies = DailyFrequency.where(
      unity_id: unities_ids,
      classroom_id: classroom_ids,
      frequency_date: days_to_process
    )

    # Filtra por período se o evento tem períodos específicos definidos
    daily_frequencies = daily_frequencies.where(period: event_periods) if event_periods.present?

    daily_frequencies.destroy_all
  end

  def search_classrooms(coverage, unities_ids)
    classroom_ids = []
    event_periods = @events.flat_map(&:periods).compact.uniq

    if coverage.include?('by_grade')
      grade_ids = @events.map(&:grade_id).uniq
      classrooms = ClassroomsGrade.joins(:classroom)
                                  .where(grade_id: grade_ids)
      classrooms = classrooms.where(classrooms: { period: event_periods }) if event_periods.present?
      classroom_ids += classrooms.pluck(:classroom_id).uniq
    end

    classroom_ids += @events.map(&:classroom_id).uniq if coverage.include?('by_classroom')

    if coverage.include?('by_unity')
      classrooms = Classroom.where(unity_id: unities_ids)
      classrooms = classrooms.where(period: event_periods) if event_periods.present?
      classroom_ids += classrooms.pluck(:id).uniq
    end

    if coverage.include?('by_course')
      course_ids = @events.map(&:course_id).uniq
      grade_ids = Grade.where(course_id: course_ids).pluck(:id).uniq
      classrooms = ClassroomsGrade.joins(:classroom)
                                  .where(grade_id: grade_ids)
      classrooms = classrooms.where(classrooms: { period: event_periods }) if event_periods.present?
      classroom_ids += classrooms.pluck(:classroom_id).uniq
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

  def destroy_school_days(school_days)
    @school_calendars.each do |school_calendar|
      school_days.each do |school_day|
        next unless SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).school_day?

        SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).destroy(@events)
      end
    end
  end

  def event_type_includes_no_school?
    (@events.pluck(:event_type) & [EventTypes::NO_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY]).any?
  end
end
