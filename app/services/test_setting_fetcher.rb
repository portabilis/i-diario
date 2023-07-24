class TestSettingFetcher
  def self.current(classroom, step = nil)
    new(classroom, step).current
  end

  def initialize(classroom, step = nil)
    @classroom = classroom
    @step = step || current_step
  end

  def current
    raise ArgumentError if @classroom.blank?

    @year = @step.try(:school_calendar).try(:year) || @classroom.year

    general_by_school_test_setting.presence ||
      general_test_setting.presence ||
      by_school_term_test_setting.presence
  end

  private

  def general_test_setting
    TestSetting.find_by(
      exam_setting_type: ExamSettingTypes::GENERAL,
      year: @year
    )
  end

  def current_step
    StepsFetcher.new(@classroom).step_by_date(Date.current)
  end

  def school_term_type_step
    return if @step.blank?

    avaliation_school_term_type_step.presence || step_school_term_type_step
  end

  def avaliation_school_term_type_step
    Avaliation.by_classroom_id(@classroom.id)
              .by_test_date_between(@step.start_at, @step.end_at)
              .first
              .try(:test_setting)
              .try(:school_term_type_step)
  end

  def step_school_term_type_step
    steps_number = @step.school_calendar_parent.steps.count
    step_number = @step.step_number

    SchoolTermTypeStep.joins(:school_term_type)
                      .where(school_term_types: { steps_number: steps_number })
                      .find_by(step_number: step_number)
  end

  # TODO - Entender o porquê algumas vezes @classroom.grade_ids está vindo vazio
  # TODO - Está fazendo essa consulta muitas vezes no banco
  def general_by_school_test_setting
    @general_by_school_test_setting ||= TestSetting.where(year: @year, exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
               .by_unities(@classroom.unity)
               .where("grades && ARRAY[?]::integer[] OR grades = '{}'", @classroom.grades.pluck(:id))
               .first
  end

  def by_school_term_test_setting
    TestSetting.find_by(year: @year, school_term_type_step: school_term_type_step)
  end
end
