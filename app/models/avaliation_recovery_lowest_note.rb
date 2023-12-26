class AvaliationRecoveryLowestNote < ApplicationRecord
  include Audit
  include Stepable
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :recovery_diary_record

  accepts_nested_attributes_for :recovery_diary_record

  delegate :classroom, :classroom_id, :discipline, :discipline_id, to: :recovery_diary_record

  scope :by_unity_id, lambda { |unity_id|
    joins(:recovery_diary_record).where(recovery_diary_records: { unity_id: unity_id })
  }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(:recovery_diary_record).where(recovery_diary_records: { classroom_id: classroom_id })
  }
  scope :by_discipline_id, lambda { |discipline_id|
    joins(:recovery_diary_record).where(recovery_diary_records: { discipline_id: discipline_id })
  }
  scope :by_created_at, lambda { |created_at| where(created_at: created_at) }
  scope :ordered, -> { order(arel_table[:recorded_at].desc) }

  before_validation :set_recorded_at, on: [:create, :update]

  validate :unique_by_step_and_classroom

  def ignore_date_validates
    new_record? && recorded_at != recorded_at_was
  end

  def set_recorded_at
    return if recovery_diary_record.blank?

    self.recovery_diary_record.recorded_at = recorded_at
  end

  def unique_by_step_and_classroom
    return if recovery_diary_record.blank? || step.blank?

    relation = AvaliationRecoveryLowestNote.by_classroom_id(classroom_id)
                                           .by_discipline_id(discipline_id)
                                           .by_step_id(classroom, step_id)

    relation = relation.where.not(id: id) if persisted?

    if relation.any?
      errors.add(:step_id, :unique_by_step_and_classroom)
    end
  end
end
