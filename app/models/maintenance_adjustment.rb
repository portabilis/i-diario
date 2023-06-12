class MaintenanceAdjustment < ApplicationRecord
  acts_as_copy_target

  include Audit
  audited
  has_associated_audits

  has_and_belongs_to_many :unities
  has_enumeration_for :status, with: MaintenanceAdjustmentStatus, create_helpers: true
  has_enumeration_for :kind, with: MaintenanceAdjustmentKinds, create_helpers: true

  validates :kind, :year, presence: true
  validates :unities, presence: true, if: :absence_adjustments?
  validates :year, mask: { with: '9999', message: :incorrect_format }

  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :by_unity, ->(unity_id) { joins(:unities).where(maintenance_adjustments_unities: { unity_id: unity_id }) }
  scope :by_year, ->(year) { where(year: year) }
  scope :by_status, ->(status) { where(status: status) }
  scope :ordered, -> { order(:created_at) }
  scope :completed, -> { by_status('completed') }

  def to_s
    MaintenanceAdjustmentKinds.t(kind)
  end
end
