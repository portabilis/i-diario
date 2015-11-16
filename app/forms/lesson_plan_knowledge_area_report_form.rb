class LessonPlanKnowledgeAreaReportForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  before_validation :date_start_must_be_a_valid_date
  before_validation :date_end_must_be_a_valid_date

  attr_accessor :unity_id,
                :classroom_id,
                :knowledge_area_id,
                :date_start,
                :date_end,
                :knowledge_area_lesson_plan

  validate :must_have_knowledge_area_lesson_plan

  def knowledge_area_lesson_plan
    KnowledgeAreaLessonPlan.joins(:lesson_plan, :knowledge_area_lesson_plan_knowledge_areas)
             .where("case when ? = 0 then 1=1 else knowledge_area_id = ? end
               and case when ? = 0 then 1 = 1 else classroom_id = ? end
               and case when ? = '01/01/1900' then  1=1 when ? = '01/01/1900' then  1=1  else lesson_plan_date between ? and ? end",
               (knowledge_area_id == '' ? 0 : knowledge_area_id), (knowledge_area_id == '' ? 0 : knowledge_area_id), (classroom_id == '' ? 0 : classroom_id), 
               (classroom_id == '' ? 0 : classroom_id), (date_start == '' ? '01/01/1900' : date_start), 
               (date_end == '' ? '01/01/1900' : date_end), (date_start == '' ? '01/01/1900' : date_start), (date_end == '' ? '01/01/1900' : date_end))
             .order("lesson_plan_date ASC")
  end

  private

  def must_have_knowledge_area_lesson_plan
    return unless errors.blank?

    if knowledge_area_lesson_plan.count == 0
      errors.add(:knowledge_area_lesson_plan, :must_have_knowledge_area_lesson_plan)
    end
  end

  def date_start_must_be_a_valid_date
    return if errors[:date_start].any?

    begin
      date_start.to_date
    rescue ArgumentError
      errors.add(:date_start, :date_start_must_be_a_valid_date)
    end
  end

  def date_end_must_be_a_valid_date
    return if errors[:date_end].any?

    begin
      date_end.to_date
    rescue ArgumentError
      errors.add(:date_end, :date_end_must_be_a_valid_date)
    end
  end
end