class TestSettingForm
  include ActiveModel::Model

  attr_accessor :exam_setting_type,
                :year,
                :school_term,
                :maximum_score,
                :number_of_decimal_places,
                :fix_tests,
                :tests_attributes

  validate :can_update_test_setting?

  def initialize(resource, attributes = {})
    @resource = resource
    @params = attributes
  end

  def save
    resource.assign_attributes(params)
    return false unless valid? && resource.valid?
    resource.save!
  end

  private

  attr_accessor :resource, :params

  def can_update_test_setting?
    if !TestSettingUpdatePolicy.can_update?(resource)
      errors.add(:base, :has_avaliation_associated)
      false
    end
  end
end
