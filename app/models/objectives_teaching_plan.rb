class ObjectivesTeachingPlan < ApplicationRecord
  audited except: [:teaching_plan_id],
          allow_mass_assignment: true,
          associated_with: [:teaching_plan, :objective]

  belongs_to :teaching_plan
  belongs_to :objective

  before_save :set_position

  private

  def set_position
    self.position = teaching_plan.objectives_created_at_position[objective.id]
  end
end
