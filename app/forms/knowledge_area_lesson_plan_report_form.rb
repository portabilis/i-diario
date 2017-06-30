class KnowledgeAreaLessonPlanReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :teacher_id,
                :classroom_id,
                :knowledge_area_id,
                :date_start,
                :date_end,
                :knowledge_area_lesson_plan

  validates :unity_id,
    :classroom_id,
    :date_start,
    :date_end,
    presence: true

  validate :date_start_must_be_a_valid_date
  validate :date_end_must_be_a_valid_date
  validate :no_retroactive_dates
  validate :must_have_knowledge_area_lesson_plan

  def knowledge_area_lesson_plan
    relation = KnowledgeAreaLessonPlan.by_unity_id(unity_id)
      .by_classroom_id(classroom_id)
      .by_date_range(date_start.to_date, date_end.to_date)
      .by_teacher_id(teacher_id)
      .order(LessonPlan.arel_table[:start_at].asc)

    relation = relation.by_knowledge_area_id(knowledge_area_id) if knowledge_area_id.present?

    relation
  end

  private

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

  def no_retroactive_dates
    return if date_start.nil? || date_end.nil?

    if date_start > date_end
      errors.add(:date_start, 'não pode ser maior que a Data final')
      errors.add(:date_end, 'deve ser maior ou igual a Data inicial')
    end
  end

  def must_have_knowledge_area_lesson_plan
    return unless errors.blank?

    if knowledge_area_lesson_plan.count == 0
      errors.add(:knowledge_area_lesson_plan, :must_have_knowledge_area_lesson_plan)
    end
  end
end
