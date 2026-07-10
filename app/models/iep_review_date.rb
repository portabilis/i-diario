class IepReviewDate < ApplicationRecord
  audited associated_with: :iep

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id

  validates :review_date, presence: true

  # TODO(PEI): bloquear a remoção quando o período já tem dados nas seções 4/5
  # (regra a ser implementada no serviço de publicação, que ainda não existe).
end
