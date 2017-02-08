class AvaliationsTestSettingUpdater
  attr_reader :name,
              :status

  def initialize(options)
    @name = options["NAME"]
  end

  def update
    if (has_params? && update_avaliations_test_setting)
      success
    else
      error
    end
  end

  private

  def has_params?
    name
  end

  def update_avaliations_test_setting
    entity = Entity.find_by_name(name)
    if entity
      entity.using_connection do
        avaliations = Avaliation.all
        avaliations.each do |avaliation|
          test_setting = get_test_setting(avaliation)
          avaliation.test_setting = test_setting
          avaliation.test_setting_test = test_setting.tests.first if test_setting.sum_calculation_type? && test_setting.tests.count == 1
          avaliation.save(validate: false)
        end
      end
    else
      false
    end
  end

  def get_test_setting(avaliation)
    school_calendar = SchoolCalendar.find_by(unity_id: avaliation.unity_id, year: avaliation.test_date.year)
    test_setting = TestSetting.find_by(year: avaliation.test_date.year, exam_setting_type: ExamSettingTypes::GENERAL)

    if test_setting.nil?
      school_term = school_calendar.school_term(avaliation.test_date)
      test_setting = TestSetting.find_by(year: avaliation.test_date.year, school_term: school_term)
    end

    test_setting
  end

  def success
    @status = I18n.t('services.avaliations_test_setting_updater.success')
  end

  def error
    @status = I18n.t('services.avaliations_test_setting_updater.error')
  end
end
