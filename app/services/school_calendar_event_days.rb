class SchoolCalendarEventDays
  def initialize(school_calendars, events, action_name)
    @school_calendars = school_calendars
    @events = events
    @action_name = action_name
  end

  def update_school_days(old_start_date = nil, old_end_date = nil)
    events_and_days = []

    @events.each do |event|
      event_type = [EventTypes::NO_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY].include?(event.event_type)

      events_and_days << [event_type, (event.start_date..event.end_date).to_a]
    end
    events_and_days.each do |event_type, days|

      case @action_name
      when 'create'
        event_type ? create_school_days(days) : destroy_school_days(days)
      when 'destroy'
        event_type ? destroy_school_days(days) : create_school_days(days)
      when 'update'
        old_days = (old_start_date..old_end_date).to_a

        if event_type
          create_school_days(days - old_days)
          destroy_school_days(old_days - days)
        else
          create_school_days(old_days - days)
          destroy_school_days(days - old_days)
        end
      end
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

    DailyFrequency.where(unity_id: unities_ids, frequency_date: days_to_destroy).destroy_all
  end

  def destroy_school_days(school_days)
    @school_calendars.each do |school_calendar|
      school_days.each do |school_day|
        next unless SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).school_day?

        SchoolDayChecker.new(school_calendar, school_day, nil, nil, nil).destroy(@events)
      end
    end
  end
end
