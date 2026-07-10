class IepVersion < ApplicationRecord
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id
  belongs_to :published_by, class_name: 'User'

  validates :name, :published_at, presence: true

  scope :recent_first, -> { order(published_at: :desc) }
  scope :current, -> { where(active: true) }   # versão vigente ("Ativo")
end
