class StepsFetcher
  def initialize(classroom)
    @classroom = classroom
  end

  def steps
    school_calendar_steps
  end

  def step(step_number)
    step_by_number(step_number)
  end

  def step_by_date(date)
    return if school_calendar.blank?

    school_calendar_steps.started_after_and_before(date).first
  end

  def steps_by_date_range(start_date, end_date)
    return if school_calendar.blank?

    school_calendar_steps.by_date_range(start_date, end_date)
  end

  def step_by_id(step_id)
    return if school_calendar.blank?

    school_calendar_steps.find_by(id: step_id)
  end

  def last_step_by_year
    return if school_calendar.blank?

    school_calendar_steps.last
  end

  def current_step
    step_by_date(Date.current)
  end

  def step_belongs_to_date?(step_id, date)
    (step_id.to_i == step_by_date(date).try(:id))
  end

  def step_belongs_to_number?(step_id, step_number)
    (step_id.to_i == step_by_number(step_number).try(:id))
  end

  def step_type
    school_calendar_classroom.present? ? StepTypes::CLASSROOM : StepTypes::GENERAL
  end

  def old_steps(step_number)
    old_steps_by_step_number(step_number)
  end

  def school_calendar
    unity_id = @classroom.is_a?(Classroom) ? @classroom.unity_id : @classroom&.map(&:unity_id)&.first
    year = @classroom.is_a?(Classroom) ? @classroom.year : @classroom&.map(&:year)&.first

    @school_calendar ||= SchoolCalendar.find_by(unity_id: unity_id, year: year)
  end

  private

  def school_calendar_classroom
    return if school_calendar.blank?

    classroom_id = @classroom.is_a?(Classroom) ? @classroom.id : @classroom&.map(&:id)
    @school_calendar_classroom ||= school_calendar.classrooms.find_by(classroom_id: classroom_id)
  end

  def school_calendar_steps
    return SchoolCalendarStep.none if school_calendar.blank?

    @school_calendar_steps ||= begin
      school_calendar_classroom.present? ? school_calendar_classroom.classroom_steps : school_calendar.steps
    end
  end

  def step_by_number(step_number)
    return if school_calendar.blank?

    school_calendar_steps.each do |step|
      return step if step.step_number == step_number.to_i
    end

    nil
  end

  def old_steps_by_step_number(step_number)
    if school_calendar_classroom.present?
      school_calendar_steps.where(SchoolCalendarClassroomStep.arel_table[:step_number].lt(step_number))
    else
      school_calendar_steps.where(SchoolCalendarStep.arel_table[:step_number].lt(step_number))
    end
  end

  def old_steps_by_date(date)
    if school_calendar_classroom.present?
      school_calendar_steps.where(SchoolCalendarClassroomStep.arel_table[:start_at].lt(date))
    else
      school_calendar_steps.where(SchoolCalendarStep.arel_table[:start_at].lt(date))
    end
  end
end
