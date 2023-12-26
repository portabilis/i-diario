class ObjectivesLessonPlan < ApplicationRecord
  audited except: [:lesson_plan_id],
          allow_mass_assignment: true,
          associated_with: [:lesson_plan, :objective]

  belongs_to :lesson_plan
  belongs_to :objective

  before_save :set_position

  private

  def set_position
    self.position = lesson_plan.objectives_created_at_position[objective.id]
  end
end
