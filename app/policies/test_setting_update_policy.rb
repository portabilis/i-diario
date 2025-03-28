class TestSettingUpdatePolicy
  def self.can_update?(*attributes)
    new(*attributes).can_update?
  end

  def initialize(test_setting)
    @test_setting = test_setting
  end

  def can_update?
    check_allowed_changes_on_test_setting && check_allowed_changes_on_tests
  end

  private
  attr_reader :test_setting

  def check_allowed_changes_on_test_setting
    return true unless has_any_change_on_test_setting? && has_any_avaliation_associated?

    return false if has_disallowed_changes?
    return false if invalid_minimum_score_change?

    true
  end

  def has_disallowed_changes?
    changed.any? { |changed_field| !allowed_fields_to_change_on_test_setting.include?(changed_field) }
  end

  def invalid_minimum_score_change?
    test_setting.changed.include?('minimum_score') &&
      test_setting.minimum_score >= test_setting.minimum_score_was
  end

  def has_any_avaliation_associated?
    test_setting.avaliations.any?
  end

  def check_allowed_changes_on_tests
    if has_any_change_on_tests?
      tests.each do |test_setting|
        next if test_setting.new_record? || test_setting.destroyed? || test_setting.avaliations.none?
        if test_setting.changed.any?{ |changed_field| !allowed_fields_to_change_on_tests.include?(changed_field) }
          return false
        end
      end
    end
    true
  end

  def changed?
    test_setting.changed?
  end

  def changed
    test_setting.changed
  end

  def has_any_change_on_test_setting?
    test_setting.changed?
  end

  def has_any_change_on_tests?
    tests.any?(&:changed?)
  end

  def tests
    test_setting.try(:tests)
  end

  def allowed_fields_to_change_on_tests
    ['description']
  end

  def allowed_fields_to_change_on_test_setting
    ['maximum_score', 'updated_at', 'minimum_score']
  end
end
