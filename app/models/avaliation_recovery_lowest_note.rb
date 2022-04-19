class AvaliationRecoveryLowestNote < ActiveRecord::Base
  include Audit
  include Stepable
  include Filterable

  audited
  has_associated_audits

  belongs_to :recovery_diary_record, dependent: :destroy

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


end
