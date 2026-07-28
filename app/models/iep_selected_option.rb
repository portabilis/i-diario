class IepSelectedOption < ApplicationRecord
  audited

  # touch: mantém o updated_at do plano (coluna "Última edição" do index) atualizado
  # ao marcar/desmarcar opções das seções 2/3 sem mexer em colunas do próprio plano.
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id, touch: true
  belongs_to :iep_option

  validates :iep_option_id, presence: true
end
