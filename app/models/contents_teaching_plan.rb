class ContentsTeachingPlan < ActiveRecord::Base
  include Audit
  audited except: [:teaching_plan_id],
          allow_mass_assignment: true,
          associated_with: [:teaching_plan, :content]

  belongs_to :teaching_plan
  belongs_to :content

  before_save :set_position

  private

  def set_position
    self.position = teaching_plan.contents_created_at_position[content.id]
  end
end
