class DisciplineLessonPlan < ActiveRecord::Base
  acts_as_copy_target

  include Audit
  audited
  has_associated_audits

  belongs_to :lesson_plan
  belongs_to :discipline

  validates :lesson_plan, presence: true
  validates :discipline, presence: true

  validates :classes, presence: true, if: :require_classes?

  private

  def require_classes?
    return unless lesson_plan.present? && lesson_plan.classroom.present?

    lesson_plan.classroom.exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end
end
