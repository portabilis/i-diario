class IepPeriodicEvaluation < ApplicationRecord
  include IepComponentSelectable

  audited associated_with: :iep

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id
  belongs_to :iep_review_date                          # revisão (1ª, 2ª...) a que a avaliação pertence

  validates :iep_review_date_id, presence: true
end
