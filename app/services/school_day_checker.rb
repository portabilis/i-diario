class SchoolDayChecker
  def initialize(school_calendar, date, grade_id, classroom_id, discipline_id)
    raise ArgumentError unless school_calendar.present? && date.present?

    @school_calendar = school_calendar
    @date = date
    @grade_id = grade_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
  end

  def school_day?
    date_is_school_day?(@date)
  end

  def next_school_day
    date = @date

    while not date_is_school_day?(date)
      date = date.next_day
    end

    date
  end

  private

  def date_is_school_day?(date)
    events_by_date = @school_calendar.events.by_date(date)
    events_by_date_without_frequency = events_by_date.without_frequency
    events_by_date_with_frequency = events_by_date.with_frequency

    if @classroom_id.present?
      if @discipline_id.present?
        return false if any_discipline_event?(events_by_date_without_frequency, @grade_id, @classroom_id, @discipline_id)
        return true if any_discipline_event?(events_by_date_with_frequency, @grade_id, @classroom_id, @discipline_id)
      end

      return false if any_classroom_event?(events_by_date_without_frequency, @grade_id, @classroom_id)
      return true if any_classroom_event?(events_by_date_with_frequency, @grade_id, @classroom_id)

      return false if any_grade_event?(events_by_date_without_frequency.by_period(classroom.period), @grade_id)
      return true if any_grade_event?(events_by_date_with_frequency.by_period(classroom.period), @grade_id)
      return false if any_course_event?(events_by_date_without_frequency.by_period(classroom.period), grade.course_id)
      return true if any_course_event?(events_by_date_with_frequency.by_period(classroom.period), grade.course_id)

      return false if any_global_event?(events_by_date_without_frequency.by_period(classroom.period))
      return true if any_global_event?(events_by_date_with_frequency.by_period(classroom.period))

    else

      if @grade_id.present?
        return false if any_grade_event?(events_by_date_without_frequency, @grade_id)
        return true if any_grade_event?(events_by_date_with_frequency, @grade_id)
      end

      return false if any_global_event?(events_by_date_without_frequency)
      return true if any_global_event?(events_by_date_with_frequency)
    end

    if @classroom_id.present? && classroom.try(:calendar)
      return false if classroom.calendar.classroom_step(date).nil?
    else
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

  def classroom
    @classroom ||= Classroom.find(@classroom_id)
  end

  def grade
    @grade ||= Grade.find(@grade_id)
  end
end
