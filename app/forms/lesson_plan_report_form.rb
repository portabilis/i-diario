class LessonPlanReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :knowledge_area_id,
                :date_start,
                :date_end,
                :global_absence,
                :discipline_lesson_plan

  validates :unity_id,       presence: true
  validate :must_have_discipline_lesson_plan

  def discipline_lesson_plan
    DisciplineLessonPlan.by_discipline_id_lesson_plan_date(discipline_id, date_start, date_end, classroom_id)
  end

  private

  def global_absence?
    global_absence == "1"
  end

  def must_have_discipline_lesson_plan
    return unless errors.blank?

    if discipline_lesson_plan.count == 0
      errors.add(:discipline_lesson_plan, :must_have_discipline_lesson_plan)
    end
  end 
end