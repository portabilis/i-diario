class KnowledgeAreaLessonPlanReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :teacher_id,
                :classroom_id,
                :knowledge_area_id,
                :date_start,
                :date_end,
                :knowledge_area_lesson_plan


  validates :date_start, presence: true, date: true, timeliness: { on_or_before: :date_end, type: :date, on_or_before_message: 'não pode ser maior que a Data final' }
  validates :date_end, presence: true, date: true, timeliness: { on_or_after: :date_start, type: :date, on_or_after_message: 'deve ser maior ou igual a Data inicial' }
  validates :classroom_id,
            presence: true
  validate :must_have_knowledge_area_lesson_plan

  def knowledge_area_lesson_plan
    relation = KnowledgeAreaLessonPlan.by_classroom_id(classroom_id)
      .by_date_range(date_start.to_date, date_end.to_date)
      .by_teacher_id(teacher_id)
      .order(LessonPlan.arel_table[:start_at].asc)

    relation = relation.by_knowledge_area_id(knowledge_area_id) if knowledge_area_id.present?

    relation
  end

  private

  def must_have_knowledge_area_lesson_plan
    return unless errors.blank?

    if knowledge_area_lesson_plan.count == 0
      errors.add(:knowledge_area_lesson_plan, :must_have_knowledge_area_lesson_plan)
    end
  end
end
