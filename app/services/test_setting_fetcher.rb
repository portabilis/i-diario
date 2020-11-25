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

    year = @step.try(:school_calendar).try(:year) || Date.current.year

    general_by_school_test_setting = general_by_school_test_setting(year)

    return general_by_school_test_setting if general_by_school_test_setting.present?

    general_test_setting = general_test_setting(year)

    return general_test_setting if general_test_setting.present?

    TestSetting.find_by(
      year: year,
      school_term: school_term
    )
  end

  private

  def general_test_setting(year)
    TestSetting.find_by(
      exam_setting_type: ExamSettingTypes::GENERAL,
      year: year
    )
  end

  def current_step
    StepsFetcher.new(@classroom).step_by_date(Date.current)
  end

  def school_term
    avaliation_school_term.presence || step_school_term
  end

  def avaliation_school_term
    Avaliation.by_classroom_id(@classroom.id)
              .by_test_date_between(@step.start_at, @step.end_at)
              .first
              .try(:test_setting)
              .try(:school_term)
  end

  def step_school_term
    SchoolTermConverter.convert(@step)
  end

  def general_by_school_test_setting(year)
    TestSetting.where(year: year, exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
               .by_unities(@classroom.unity)
               .where("grades @> ARRAY[?]::integer[] OR grades = '{}'", @classroom.grade)
               .first
  end
end
