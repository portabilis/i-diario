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
    avaliation_step = StepsFetcher.new(avaliation.classroom).step_by_date(avaliation.test_date)

    TestSettingFetcher.current(avaliation.classroom, avaliation_step)
  end

  def success
    @status = I18n.t('services.avaliations_test_setting_updater.success')
  end

  def error
    @status = I18n.t('services.avaliations_test_setting_updater.error')
  end
end
