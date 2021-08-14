require 'active_support/concern'

module TestSettingValidations
  extend ActiveSupport::Concern

  included do
    validates :exam_setting_type, presence: true
    validates :year, presence: true
    validates :average_calculation_type, presence: true
    validates :school_term_type_step, presence: { if: :by_school_term?  }
    validates :unities, presence: true, if: :general_by_school?
    validates :default_division_weight,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 1000
              }, if: :general_by_school?
    validates :maximum_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }
    validates :number_of_decimal_places, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }

    validate :uniqueness_of_general_test_setting,        if: :general?
    validate :uniqueness_of_by_school_term_test_setting, if: :by_school_term?
    validate :uniqueness_of_by_general_by_school_test_setting, if: :general_by_school?
    validate :at_least_one_assigned_test, if: :sum?
    validate :tests_weight_less_or_equal_maximum_score, if: :should_validate_tests_weight?
    validate :ensure_can_destroy_test_settings
  end

  private

  def uniqueness_of_general_test_setting
    test_settings = TestSetting.where(year: year).where.not(exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
    test_settings = test_settings.where.not(id: id) if persisted?

    errors.add(:year, :taken) if test_settings.any?
  end

  def uniqueness_of_by_school_term_test_setting
    general_test_settings = TestSetting.where(year: year, exam_setting_type: ExamSettingTypes::GENERAL)
    general_test_settings = general_test_settings.where.not(id: id) if persisted?

    by_school_term_test_settings = TestSetting.where(year: year, school_term_type_step: school_term_type_step)
    by_school_term_test_settings = by_school_term_test_settings.where.not(id: id) if persisted?

    errors.add(:year, :taken) if general_test_settings.any?
    errors.add(:school_term_type_step, :taken) if by_school_term_test_settings.any?
  end

  def uniqueness_of_by_general_by_school_test_setting
    test_settings = TestSetting.where(year: year, exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
    test_settings = test_settings.where.not(id: id) if persisted?
    test_settings = test_settings.by_unities(unities)
    test_settings = test_settings.where("grades && ARRAY[?]::integer[] OR grades = '{}'", grades) if grades.present?

    return unless test_settings.any?

    errors.add(:unities, :taken)
    errors.add(:grades, :taken)
  end

  def at_least_one_assigned_test
    errors.add(:tests, :at_least_one_assigned_test) if tests.empty? { |test| !test.marked_for_destruction? }
  end

  def should_validate_tests_weight?
    sum? && tests.any? { |test| !test.marked_for_destruction? } && maximum_score
  end

  def tests_weight_less_or_equal_maximum_score
    return if default_division_weight.blank?

    tests_weight = tests.to_a.select { |test| !test.marked_for_destruction? && test.weight }.sum(&:weight)

    errors.add(:tests, :tests_weight_less_or_equal_maximum_score) unless (tests_weight / default_division_weight) <= maximum_score
  end

  def ensure_can_destroy_test_settings
    if tests.any?
      tests.each do |test_setting|
        if test_setting.avaliations.any? && test_setting.marked_for_destruction?
          errors.add(:base, :has_avaliation_associated)
          return false
        end
      end
    end
  end
end
