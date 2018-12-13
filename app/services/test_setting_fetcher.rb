class TestSettingFetcher
  def initialize(school_calendar_step)
    @school_calendar_step = school_calendar_step
  end

  def self.fetch(school_calendar_step)
    new(school_calendar_step).fetch
  end

  def fetch
    test_seting = TestSetting.find_by(
      exam_setting_type: ExamSettingTypes::GENERAL,
      year: @school_calendar_step.school_calendar.year
    )

    if test_seting.blank?
      school_term = @school_calendar_step.school_term
      test_seting = TestSetting.find_by(
        year: @school_calendar_step.school_calendar.year,
        school_term: school_term
      )
    end

    test_seting
  end
end
