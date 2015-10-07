class KnowledgeAreaLessonPlan < ActiveRecord::Base
  acts_as_copy_target

  include Audit
  audited
  has_associated_audits

  belongs_to :lesson_plan

  validates :lesson_plan, presence: true
end
