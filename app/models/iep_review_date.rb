class IepReviewDate < ApplicationRecord
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id

  validates :review_date, presence: true

  # O bloqueio de remoção quando o período já tem dados preenchidos nas seções 4/5
  # é aplicado no serviço de publicação do PEI, não aqui.
end
