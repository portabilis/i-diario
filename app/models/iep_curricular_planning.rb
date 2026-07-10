class IepCurricularPlanning < ApplicationRecord
  include IepMultiSelectable
  include IepComponentSelectable

  audited associated_with: :iep

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id
  belongs_to :school_term_type_step                    # opcional (null = anual)

  # class_name e foreign_key inferidos: a associação casa com o model
  # (IepCurricularPlanningOption) e a coluna com a convenção (iep_curricular_planning_id).
  has_many :iep_curricular_planning_options, dependent: :destroy

  accepts_nested_attributes_for :iep_curricular_planning_options, allow_destroy: true

  # Acomodações da seção 4 — mesma mecânica de multi-select por tipo das seções 2/3
  iep_multi_select :iep_curricular_planning_options,
                   :instructional_accommodation, :environmental_accommodation,
                   :assessment_accommodation
end
