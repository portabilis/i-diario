class IepPeriodicEvaluation < ApplicationRecord
  include IepComponentSelectable

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id
  belongs_to :school_term_type_step                    # opcional (null = anual)
end
