class ContentsTeachingPlan < ActiveRecord::Base
  include Audit
  audited except: [:teaching_plan_id],
          allow_mass_assignment: true,
          associated_with: [:teaching_plan, :content]

  belongs_to :teaching_plan
  belongs_to :content
end