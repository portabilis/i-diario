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

  def create(event = nil)
    if event.present?
      return if event.coverage != "by_unity"

      school_type = [EventTypes::EXTRA_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY]
      dates = [*event.start_date..event.end_date]

      dates.each do |date|
        UnitySchoolDay.find_or_create_by(unity_id: @school_calendar.unity_id, school_day: date) if school_type.include?(event.event_type) && [0, 6].include?(@date.wday)
      end
    else
      UnitySchoolDay.find_or_create_by(unity_id: @school_calendar.unity_id, school_day: @date)
    end
  end

  def destroy(event = nil)
    if event.present?
      return if event.coverage != "by_unity"

      no_school_event_type = [EventTypes::NO_SCHOOL_WITH_FREQUENCY, EventTypes::NO_SCHOOL]
      dates = [*event.start_date..event.end_date]

      dates.each do |date|
        UnitySchoolDay.where(unity_id: @school_calendar.unity_id, school_day: date).destroy_all if no_school_event_type.include?(event.event_type) && ![0, 6].include?(@date.wday) || !no_school_event_type.include?(event.event_type) && [0,6].include?(@date.wday)
      end
    else
      UnitySchoolDay.where(unity_id: @school_calendar.unity_id, school_day: @date).destroy_all
    end
  end

  def next_school_day
    date = @date

    while not date_is_school_day?(date)
      date = date.next_day
    end

    date
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

  def date_is_school_day?(date)
    events_by_date = @school_calendar.events.by_date(date)
    events_by_date_no_school = events_by_date.no_school_event
    events_by_date_school = events_by_date.school_event

    if @classroom_id.present?
      if @discipline_id.present?
        return false if any_discipline_event?(events_by_date_no_school, @grade_id, @classroom_id, @discipline_id)
        return true if any_discipline_event?(events_by_date_school, @grade_id, @classroom_id, @discipline_id)
      end

      return false if any_classroom_event?(events_by_date_no_school, @grade_id, @classroom_id)
      return true if any_classroom_event?(events_by_date_school, @grade_id, @classroom_id)

      return false if any_grade_event?(events_by_date_no_school.by_period(classroom.period), @grade_id)
      return true if any_grade_event?(events_by_date_school.by_period(classroom.period), @grade_id)
      return false if any_course_event?(events_by_date_no_school.by_period(classroom.period), grade.course_id)
      return true if any_course_event?(events_by_date_school.by_period(classroom.period), grade.course_id)

      return false if any_global_event?(events_by_date_no_school.by_period(classroom.period))
      return true if any_global_event?(events_by_date_school.by_period(classroom.period))
      return false if steps_fetcher.step_by_date(date).nil?
    else
      if @grade_id.present?
        return false if any_grade_event?(events_by_date_no_school, @grade_id)
        return true if any_grade_event?(events_by_date_school, @grade_id)
      end
      return false if events_by_date_no_school.exists?
      return true if events_by_date_school.exists?
      return false if @school_calendar.step(date).nil?
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

  def grade
    @grade ||= Grade.find(@grade_id)
  end

  def limit_of_dates_to_check(number_of_days)
    number_of_days * 2
  end
end
