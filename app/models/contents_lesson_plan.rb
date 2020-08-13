class ContentsLessonPlan < ActiveRecord::Base
  include Audit
  audited except: [:lesson_plan_id],
          allow_mass_assignment: true,
          associated_with: [:lesson_plan, :content]

  belongs_to :lesson_plan
  belongs_to :content

  before_save :set_position

  private

  def set_position
    self.position = lesson_plan.contents_created_at_position[content.id]
  end
end
