class ContentsLessonPlan < ActiveRecord::Base
  include Audit
  audited except: [:lesson_plan_id],
          allow_mass_assignment: true,
          associated_with: [:lesson_plan, :content]

  belongs_to :lesson_plan
  belongs_to :content
end