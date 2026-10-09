class IepMedication < ApplicationRecord
  audited associated_with: :iep

  # touch: mantém o updated_at do plano (coluna "Última edição" do index) atualizado
  # ao adicionar/remover um medicamento sem mexer em colunas do próprio plano.
  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id, touch: true

  # A coluna aceita NULL porque a migração do campo único preservou linhas só com dosagem ou
  # horário; como o autosave só valida linha alterada, essas linhas não travam outras edições.
  validates :name, presence: true
end
