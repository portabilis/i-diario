class TestSettingUpdater
  def update!
    @test_setting.assign_attributes params
    @test_setting.save if validate_test_setting_changes
    @test_setting
  end


  def initialize(params)
    @test_setting = params.fetch(:test_setting, test_setting)
    @params = params.fetch(:params, [])
  end

  private

  attr_reader :params

  def test_setting
    TestSetting.new
  end

  def validate_test_setting_changes
    if !can_update_test_setting?
      @test_setting.errors.add(:base, :has_avaliation_associated)
      false
    end
  end

  def can_update_test_setting?
    TestSettingUpdatePolicy.can_update?(@test_setting)
  end
end
