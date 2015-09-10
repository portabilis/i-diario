class TestSetting < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  has_enumeration_for :exam_setting_type, with: ExamSettingTypes, create_helpers: true

  has_many :avaliations, dependent: :restrict_with_error
  has_many :tests, class_name: 'TestSettingTest', dependent: :destroy

  accepts_nested_attributes_for :tests, reject_if: :all_blank, allow_destroy: true

  validates :exam_setting_type, presence: true
  validates :year, presence: true
  validates :school_term, presence: { if: :by_school_term?  }
  validates :maximum_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }
  validates :number_of_decimal_places, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }

  validate :uniqueness_of_general_test_setting,        if: :general?
  validate :uniqueness_of_by_school_term_test_setting, if: :by_school_term?
  validate :at_least_one_assigned_regular_test, if: :fix_tests?
  validate :regular_tests_weight_equal_maximum_score, if: :should_validate_regular_tests_weight?
  validate :recovery_tests_weight_equal_maximum_score, if: :should_validate_recovery_tests_weight?


  scope :ordered, -> { order(arel_table[:year]) }

  def to_s
    year
  end

  private

  def uniqueness_of_general_test_setting
    test_settings = TestSetting.where(year: year)
    test_settings = test_settings.where.not(id: id) if persisted?

    errors.add(:year, :taken) if test_settings.any?
  end

  def uniqueness_of_by_school_term_test_setting
    general_test_settings = TestSetting.where(year: year, exam_setting_type: ExamSettingTypes::GENERAL)
    general_test_settings = general_test_settings.where.not(id: id) if persisted?

    by_school_term_test_settings = TestSetting.where(year: year, school_term: school_term)
    by_school_term_test_settings = by_school_term_test_settings.where.not(id: id) if persisted?

    errors.add(:year, :taken) if general_test_settings.any?
    errors.add(:school_term, :taken) if by_school_term_test_settings.any?
  end

  def at_least_one_assigned_regular_test
    errors.add(:tests, :at_least_one_assigned_regular_test) unless tests.any? { |test| test.test_type == TestTypes::REGULAR && !test.marked_for_destruction? }
  end

  def should_validate_regular_tests_weight?
    fix_tests? && tests.any? { |test| test.test_type == TestTypes::REGULAR && !test.marked_for_destruction? } && maximum_score
  end

  def regular_tests_weight_equal_maximum_score
    if tests.to_a.select { |test| test.test_type == TestTypes::REGULAR && !test.marked_for_destruction? }.sum(&:weight) != maximum_score
      errors.add(:tests, :regular_tests_weight_equal_maximum_score)
    end
  end

  def should_validate_recovery_tests_weight?
    fix_tests? && tests.any? { |test| test.test_type == TestTypes::RECOVERY && !test.marked_for_destruction? } && maximum_score
  end

  def recovery_tests_weight_equal_maximum_score
    if tests.to_a.select { |test| test.test_type == TestTypes::RECOVERY && !test.marked_for_destruction? }.sum(&:weight) != maximum_score
      errors.add(:tests, :recovery_tests_weight_equal_maximum_score)
    end
  end
end
