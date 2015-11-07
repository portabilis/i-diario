class LessonPlanReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :knowledge_area_id,
                :date_start,
                :date_end,
                :global_absence,
                :discipline_lesson_plan,
                :knowledge_area_lesson_plan

  validates :unity_id,       presence: true
  validates :classroom_id,   presence: true
  validates :date_start,     presence: true
  validates :date_end,       presence: true
  validates :global_absence, presence: true

  validate :must_have_discipline_lesson_plan
  validate :must_have_knowledge_area_lesson_plan
  validate :has_classroom


  def knowledge_area_lesson_plan
    KnowledgeAreaLessonPlan.by_knowledge_area_id_lesson_plan_date(knowledge_area_id, date_start, date_end, classroom_id)
  end

  def discipline_lesson_plan
    DisciplineLessonPlan.by_discipline_id_lesson_plan_date(discipline_id, date_start, date_end, classroom_id)
  end

  private

  def global_absence?
    global_absence == "1"
  end

  def must_have_discipline_lesson_plan
    return unless errors.blank?

    if discipline_lesson_plan.count == 0 && discipline_id.present?
      errors.add(:discipline_lesson_plan, :must_have_discipline_lesson_plan)
    end
  end 

  def must_have_knowledge_area_lesson_plan
    return unless errors.blank?

    if knowledge_area_lesson_plan.count == 0 && knowledge_area_id.present?
      errors.add(:knowledge_area_lesson_plan, :must_have_knowledge_area_lesson_plan)
    end
  end

  def has_classroom
    return unless errors.blank?

    if discipline_id.present? && !knowledge_area_id.present? && !classroom_id.present?
      errors.add(:classroom_id, :has_classroom)
    end
  end
end