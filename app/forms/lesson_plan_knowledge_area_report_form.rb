class LessonPlanKnowledgeAreaReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :knowledge_area_id,
                :date_start,
                :date_end,
                :global_absence,
                :knowledge_area_lesson_plan

  validates :unity_id,       presence: true
  validate :must_have_knowledge_area_lesson_plan

  def knowledge_area_lesson_plan
    KnowledgeAreaLessonPlan.by_knowledge_area_id_lesson_plan_date(knowledge_area_id, date_start, date_end, classroom_id)
  end

  private

  def global_absence?
    global_absence == "1"
  end

  def must_have_knowledge_area_lesson_plan
    return unless errors.blank?

    if knowledge_area_lesson_plan.count == 0 && knowledge_area_id.present?
      errors.add(:knowledge_area_lesson_plan, :must_have_knowledge_area_lesson_plan)
    end
  end
end