class TestSetting < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit
  include TestSettingValidations

  has_enumeration_for :exam_setting_type, with: ExamSettingTypes, create_helpers: true
  has_enumeration_for :average_calculation_type, with: AverageCalculationTypes, create_helpers: true

  has_many :avaliations, dependent: :restrict_with_error
  has_many :tests, class_name: 'TestSettingTest', dependent: :destroy
  belongs_to :school_term_type_step

  accepts_nested_attributes_for :tests, reject_if: :all_blank, allow_destroy: true

  scope :ordered, -> { order(year: :desc) }
  scope :by_unities, ->(unities) { where('unities @> ARRAY[?]::integer[]', unities) }
  scope :by_grades, ->(grades) { where('grades @> ARRAY[?]::integer[]', grades) }

  validate :can_update_test_setting?, on: :update

  def to_s
    school_term_type_step ? school_term_humanize : year.to_s
  end

  def school_term_humanize
    return '-' unless school_term_type_step

    school_term_type_step.to_s
  end

  def can_update_test_setting?
    if !TestSettingUpdatePolicy.can_update?(self)
      errors.add(:base, :has_avaliation_associated)
      false
    end
  end

  def sum_calculation_type?
    average_calculation_type == AverageCalculationTypes::SUM
  end

  def arithmetic_calculation_type?
    average_calculation_type == AverageCalculationTypes::ARITHMETIC
  end

  def arithmetic_and_sum_calculation_type?
    average_calculation_type == AverageCalculationTypes::ARITHMETIC_AND_SUM
  end
end
