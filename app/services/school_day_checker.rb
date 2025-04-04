class SchoolDayChecker
  def initialize(school_calendar, date, grade_id, classroom_id, discipline_id)
    raise ArgumentError unless school_calendar.present? && date.present?

    @school_calendar = get_school_calendar(school_calendar, classroom_id)
    @date = date
    @grade_id = grade_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
  end

  def school_day?
    date_is_school_day?(@date)
  end

  def day_allows_entry?
    date_allows_entry?(@date)
  end

  def create(events)
    [events].flatten.each do |event|
      return if event.coverage != "by_unity"

      school_type = [EventTypes::EXTRA_SCHOOL, EventTypes::NO_SCHOOL_WITH_FREQUENCY]
      without_frequency = [EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY, EventTypes::NO_SCHOOL]
      dates = [*event.start_date..event.end_date]

      dates.each do |date|
        if school_type.include?(event.event_type) && [0, 6].include?(@date.wday)
          unities_ids.each do |unity_id|
            UnitySchoolDay.find_or_create_by(unity_id: unity_id, school_day: date)
          end
        elsif without_frequency.include?(event.event_type)
          UnitySchoolDay.where(unity_id: unities_ids, school_day: date).destroy_all
        end
      end
    end
  end

  def destroy(events)
    [events].flatten.each do |event|
      return if event.coverage != "by_unity"

      dates = [*event.start_date..event.end_date]

      dates.each do |date|
        UnitySchoolDay.where(unity_id: unities_ids, school_day: date).destroy_all
      end
    end
  end

  def school_dates_between(start_date, end_date)
    start_date.upto(end_date).select do |current_date|
      date_is_school_day?(current_date)
    end
  end

  def school_dates_since(date, number_of_days)
    selected_school_dates = []
    last_date_to_check = date - limit_of_dates_to_check(number_of_days)

    date.downto(last_date_to_check).each do |current_date|
      break if selected_school_dates.size == number_of_days

      selected_school_dates << current_date if date_is_school_day?(current_date)
    end

    selected_school_dates
  end

  private

  def get_school_calendar(school_calendar, classroom_id)
    return school_calendar if classroom_id.nil?

    classroom = Classroom.find(classroom_id)
    if classroom.unity.eql?(school_calendar.unity)
      return school_calendar
    else
      new_school_calendar = classroom.unity.school_calendars.where(year: Date.current.year.to_s).last
      return new_school_calendar if new_school_calendar
    end

    return school_calendar
  end

  # Checks if date has 'No school' events, used mainly in 'Pedagogical tracking' to
  # count 'School' days
  def date_is_school_day?(date)
    [@school_calendar].each do |school_calendar|
      events_by_date = school_calendar.events.by_date(date)
      events_by_date_no_school = events_by_date.no_school_event
      events_by_date_school = events_by_date.school_event

      return check_for_events(events_by_date_no_school, events_by_date_school, date, school_calendar)
    end
  end

  # Checks if date allows entries (frequency, notes, ...) to be saved
  # Used mainly for validations
  def date_allows_entry?(date)
    [@school_calendar].each do |school_calendar|
      events_by_date = school_calendar.events.by_date(date)
      events_by_date_no_frequency = events_by_date.events_to_report
      events_by_date_with_frequency = events_by_date.events_with_frequency

      return check_for_events(events_by_date_no_frequency, events_by_date_with_frequency, date, school_calendar)
    end
  end

  def check_for_events(not_allowed_events, allowed_events, date, school_calendar)
    if @classroom_id.present?
      if @discipline_id.present?
        return false if any_discipline_event?(not_allowed_events, @grade_id, @classroom_id, @discipline_id)
        return true if any_discipline_event?(allowed_events, @grade_id, @classroom_id, @discipline_id)
      end

      return false if any_classroom_event?(not_allowed_events, @grade_id, @classroom_id)
      return true if any_classroom_event?(allowed_events, @grade_id, @classroom_id)

      return false if any_grade_event?(not_allowed_events.by_period(classroom.period), @grade_id)
      return true if any_grade_event?(allowed_events.by_period(classroom.period), @grade_id)
      return false if any_course_event?(not_allowed_events.by_period(classroom.period), grade_course_ids)
      return true if any_course_event?(allowed_events.by_period(classroom.period), grade_course_ids)

      return false if any_global_event?(not_allowed_events.by_period(classroom.period))
      return true if any_global_event?(allowed_events.by_period(classroom.period))
      return false if steps_fetcher.step_by_date(date).nil?
    else
      if @grade_id.present?
        return false if any_grade_event?(not_allowed_events, @grade_id)
        return true if any_grade_event?(allowed_events, @grade_id)
      end
      return false if not_allowed_events.exists?
      return true if allowed_events.exists?
      return false if school_calendar.step(date).nil?
    end
    ![0, 6].include? date.wday
  end

  def any_discipline_event?(query, grade_id, classroom_id, discipline_id)
    query.by_grade(grade_id)
         .by_classroom_id(classroom_id)
         .by_discipline_id(discipline_id)
         .any?
  end

  def any_classroom_event?(query, grade_id, classroom_id)
    query.by_grade(grade_id)
         .without_discipline
         .by_classroom_id(classroom_id)
         .any?
  end

  def any_grade_event?(query, grade_id)
    query.by_grade(grade_id)
         .without_classroom
         .any?
  end

  def any_course_event?(query, course_id)
    query.by_course(course_id)
         .without_grade
         .without_classroom
         .any?
  end

  def any_global_event?(query)
    query.without_course
         .without_grade
         .without_classroom
         .any?
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def classroom
    @classroom ||= Classroom.find(@classroom_id)
  end

  def grade_course_ids
    @grade_course_ids ||= Grade.where(id: @grade_id).pluck(:course_id)
  end

  def unities_ids
    @unities_ids ||= [@school_calendar].flatten.map(&:unity_id)
  end

  def limit_of_dates_to_check(number_of_days)
    number_of_days * 2
  end
end
