class TestSetting < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  has_many :tests, class_name: "TestSettingTest", dependent: :destroy

  validates :year, uniqueness: true, presence: true
  validate :tests_weight_equal_ten
  validate :at_least_one_assigned_test, if: :fix_tests?

  scope :ordered, -> { order(arel_table[:year]) }

  accepts_nested_attributes_for :tests, reject_if: :all_blank, allow_destroy: true

  def to_s
    year
  end

  private

  def tests_weight_equal_ten
    return unless fix_tests? && tests.present?

    errors.add(:tests, :weight_must_be_ten) if tests.to_a.select{|t| t.test_type == TestTypes::REGULAR && !t.marked_for_destruction?}.sum(&:weight) != 10

    recovery_tests = tests.to_a.select{|t| t.test_type == TestTypes::RECOVERY && !t.marked_for_destruction?}

    errors.add(:tests, :weight_must_be_ten) if recovery_tests.any? && recovery_tests.sum(&:weight) != 10
  end

  def at_least_one_assigned_test
    errors.add(:tests, :at_least_one_test) if tests.empty?
  end
end
