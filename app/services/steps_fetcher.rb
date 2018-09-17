class StepsFetcher
  def initialize(classroom)
    @classroom = classroom
  end

  def steps
    school_calendar_steps
  end

  def step(date)
    step_by_date(date)
  end

  def current_step
    step_by_date(Date.current)
  end

  def step_belongs_to_date?(step_id, date)
    (step_id.to_i == step_by_date(date).try(:id))
  end

  def step_type
    school_calendar_classroom.present? ? StepTypes::CLASSROOM : StepTypes::GENERAL
  end

  private

  def school_calendar
    @school_calendar ||= SchoolCalendar.find_by(unity_id: @classroom.unity_id, year: @classroom.year)
  end

  def school_calendar_classroom
    @school_calendar_classroom ||= school_calendar.classrooms.find_by_classroom_id(@classroom.id)
  end

  def school_calendar_steps
    @steps ||= school_calendar_classroom.present? ? school_calendar_classroom.classroom_steps : school_calendar.steps
  end

  def step_by_date(date)
    school_calendar_steps.started_after_and_before(date).first
  end
end
