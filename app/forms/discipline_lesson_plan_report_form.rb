class DisciplineLessonPlanReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :date_start,
                :date_end,
                :discipline_lesson_plan,
                :teacher_id

  validates :unity_id,
    :classroom_id,
    :discipline_id,
    :date_start,
    :date_end,
    :teacher_id,
    presence: true

  validate :date_start_must_be_a_valid_date
  validate :date_end_must_be_a_valid_date
  validate :start_at_must_be_less_than_or_equal_to_end_at
  validate :must_have_discipline_lesson_plan

  def discipline_lesson_plan
    DisciplineLessonPlan.by_unity_id(unity_id)
      .by_teacher_id(teacher_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_date_range(date_start.to_date, date_end.to_date)
      .order(LessonPlan.arel_table[:start_at].asc)
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

  def start_at_must_be_less_than_or_equal_to_end_at
    return if errors[:date_start].any? || errors[:date_end].any?

    if date_start.to_date > date_end.to_date
      errors.add(:date_start, :date_start_must_be_less_than_or_equal_to_end_at)
    end
  end

  def must_have_discipline_lesson_plan
    return unless errors.blank?

    if discipline_lesson_plan.count == 0
      errors.add(:discipline_lesson_plan, :must_have_discipline_lesson_plan)
    end
  end
end
