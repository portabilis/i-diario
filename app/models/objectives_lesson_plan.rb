class ObjectivesLessonPlan < ActiveRecord::Base
  audited except: [:lesson_plan_id],
          allow_mass_assignment: true,
          associated_with: [:lesson_plan, :objective]

  belongs_to :lesson_plan
  belongs_to :objective
end
