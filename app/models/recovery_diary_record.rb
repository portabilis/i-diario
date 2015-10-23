class RecoveryDiaryRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline

  has_many :students, class_name: 'RecoveryDiaryRecordStudent', dependent: :destroy

  accepts_nested_attributes_for :students, allow_destroy: true

  has_one :school_term_recovery_diary_record
  has_one :final_recovery_diary_record

  validates :unity, presence: true
  validates :classroom, presence: true
  validates :discipline, presence: true
  validates :recorded_at, presence: true,
                          uniqueness: { scope: [:unity_id, :classroom_id, :discipline_id] }

  validate :at_least_one_assigned_student
  validate :recorded_at_must_be_less_than_or_equal_to_today

  before_validation :self_assign_to_students

  private

  def at_least_one_assigned_student
    errors.add(:students, :at_least_one_assigned_student) if students.reject(&:marked_for_destruction?).empty?
  end

  def recorded_at_must_be_less_than_or_equal_to_today
    return unless recorded_at

    if recorded_at > Date.today
      errors.add(:recorded_at, :recorded_at_must_be_less_than_or_equal_to_today)
    end
  end

  def self_assign_to_students
    students.each { |student| student.recovery_diary_record = self }
  end
end
