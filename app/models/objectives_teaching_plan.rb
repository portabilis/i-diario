class ObjectivesTeachingPlan < ActiveRecord::Base
  audited except: [:teaching_plan_id],
          allow_mass_assignment: true,
          associated_with: [:teaching_plan, :objective]

  belongs_to :teaching_plan
  belongs_to :objective
end
