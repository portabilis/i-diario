class IepOption < ApplicationRecord
  has_enumeration_for :kind, with: IepOptionKinds

  validates :kind, :description, presence: true

  scope :enabled, -> { where(active: true) }
  scope :ordered, -> { order(:position) }
  scope :by_kind, ->(kind) { where(kind: IepOptionKinds.value_of(kind)) }
end
