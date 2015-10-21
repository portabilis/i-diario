class RecoveryDiaryRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited

  belongs_to :unity
  belongs_to :classroom, -> { includes(:exam_rule) }
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

  private

  def at_least_one_assigned_student
    errors.add(:students, :at_least_one_assigned_student) if students.reject(&:marked_for_destruction?).empty?
  end
end
