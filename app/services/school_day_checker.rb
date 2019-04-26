class SchoolDayChecker
  CHECKERS_WHEN_CLASSROOM_PRESENT = [:discipline, :classroom, :classroom_grade, :course, :classroom_global].freeze
  CHECKERS_WHEN_CLASSROOM_NIL = [:grade, :global].freeze

  def initialize(
    school_calendar,
    date,
    grade_or_grade_id = nil,
    classroom_or_classroom_id = nil,
    discipline_or_discipline_id = nil
  )
    raise ArgumentError if school_calendar.nil? && date.nil?

    @school_calendar = school_calendar
    @date = date
    @grade_id = fetch_id(grade_or_grade_id)
    @classroom_id = fetch_id(classroom_or_classroom_id)
    @discipline_id = fetch_id(discipline_or_discipline_id)
  end

  def school_day?
    for_each_checker(checker_methods) do |result|
      return result unless result.nil?
    end

    return false if classroom && classroom.calendar && classroom.calendar.classroom_step(@date).nil?
    return false if @school_calendar.step(@date).nil?

    weekday?
  end

  private

  def events_by_date
    @events_by_date ||= @school_calendar.events.by_date(@date)
  end

  def events_by_date_without_frequency
    @events_by_date_without_frequency ||= events_by_date.without_frequency
  end

  def events_by_date_with_frequency
    @events_by_date_with_frequency ||= events_by_date.with_frequency
  end

  def checker_methods
    return CHECKERS_WHEN_CLASSROOM_NIL if @classroom_id.nil?

    CHECKERS_WHEN_CLASSROOM_PRESENT
  end

  def for_each_checker(keys)
    keys.each do |key|
      yield(send("any_#{key}_event?"))
    end
  end

  def weekday?
    !(@date.saturday? || @date.sunday?)
  end

  def any_discipline_event?
    return if @discipline_id.nil?
    return false if any_discipline_event_found?(events_by_date_without_frequency)
    return true if any_discipline_event_found?(events_by_date_with_frequency)
  end

  def any_discipline_event_found?(query)
    query.by_grade(@grade_id)
         .by_classroom_id(@classroom_id)
         .by_discipline_id(@discipline_id)
         .any?
  end

  def any_classroom_event?
    return false if any_classroom_event_found?(events_by_date_without_frequency)
    return true if any_classroom_event_found?(events_by_date_with_frequency)
  end

  def any_classroom_event_found?(query)
    query.by_grade(@grade_id)
         .without_discipline
         .by_classroom_id(@classroom_id)
         .any?
  end

  def any_classroom_grade_event?
    return false if any_grade_event_found?(events_by_date_without_frequency.by_period(classroom.period))
    return true if any_grade_event_found?(events_by_date_with_frequency.by_period(classroom.period))
  end

  def any_grade_event?
    return if @grade_id.present?
    return false if any_grade_event_found?(events_by_date_without_frequency)
    return true if any_grade_event_found?(events_by_date_with_frequency)
  end

  def any_grade_event_found?(query)
    query.by_grade(@grade_id)
         .without_classroom
         .any?
  end

  def any_course_event?
    return false if any_course_event_found?(events_by_date_without_frequency.by_period(classroom.period))
    return true if any_course_event_found?(events_by_date_with_frequency.by_period(classroom.period))
  end

  def any_course_event_found?(query)
    query.by_course(grade.course_id)
         .without_grade
         .without_classroom
         .any?
  end

  def any_global_event?
    return false if any_global_event_found?(events_by_date_without_frequency)
    return true if any_global_event_found?(events_by_date_with_frequency)
  end

  def any_classroom_global_event?
    return false if any_global_event_found?(events_by_date_without_frequency.by_period(classroom.period))
    return true if any_global_event_found?(events_by_date_with_frequency.by_period(classroom.period))
  end

  def any_global_event_found?(query)
    query.without_course
         .without_grade
         .without_classroom
         .any?
  end

  def classroom
    return if @classroom_id.nil?

    @classroom ||= Classroom.find(@classroom_id)
  end

  def grade
    return if @grade_id.nil?

    @grade ||= Grade.find(@grade_id)
  end

  def fetch_id(record_or_record_id)
    return record_or_record_id.id if record_or_record_id.is_a?(ActiveRecord::Base)

    record_or_record_id
  end
end
