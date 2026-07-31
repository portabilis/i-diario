class IepCurricularPlanningOption < ApplicationRecord
  audited

  # touch: cascateia até o plano (planning → iep, ambos com touch) para atualizar o
  # updated_at (coluna "Última edição" do index) ao editar só as acomodações da seção 4.
  belongs_to :iep_curricular_planning, touch: true
  belongs_to :iep_option

  validates :iep_option_id, presence: true
end
