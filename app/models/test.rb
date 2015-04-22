class Test < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar
  belongs_to :test_setting
  delegate :fix_tests?, to: :test_setting
  belongs_to :test_setting_test

  validates :unity, :classroom, :discipline, :test_date, :class_number, :test_setting, :school_calendar, presence: true
  validates :test_setting_test, presence: true, if: :fix_tests?
  validates :description, presence: true, unless: :fix_tests?
  validate :unique_test_setting_test_per_step
  validate :is_school_day?

  scope :ordered, -> { order(arel_table[:test_date]) }

  def to_s
    test_setting_test || description
  end

  private

  def is_school_day?
    return unless school_calendar && test_date

    errors.add(:test_date, :must_be_school_day) if !school_calendar.school_day? test_date
  end

  def step
    school_calendar.step(test_date)
  end

  def unique_test_setting_test_per_step
    return unless step

    relation = Test
    if persisted?
      relation = relation.where(Test.arel_table[:id].not_eq(id))
    end
    relation = relation.where(Test.arel_table[:test_setting_test_id].eq(test_setting_test_id))
    relation = relation.where(Test.arel_table[:classroom_id].eq(classroom_id))
    relation = relation.where(Test.arel_table[:discipline_id].eq(discipline_id))
    relation = relation.where(Test.arel_table[:test_date].gteq(step.start_at))
    relation = relation.where(Test.arel_table[:test_date].lteq(step.end_at))

    errors.add(:test_setting_test, :unique_per_step) if relation.any?
  end
end