class DisciplineLessonPlanReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :date_start,
                :date_end,
                :discipline_lesson_plan,
                :teacher_id,
                :report_type

  validates :unity_id,
    :classroom_id,
    :discipline_id,
    :date_start,
    :date_end,
    :teacher_id,
    presence: true

  validate :date_start_must_be_a_valid_date
  validate :date_end_must_be_a_valid_date
  validate :no_retroactive_dates
  validate :must_have_records

  def discipline_lesson_plan
    DisciplineLessonPlan.by_unity_id(unity_id)
      .by_teacher_id(teacher_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_date_range(date_start.to_date, date_end.to_date)
      .order(LessonPlan.arel_table[:start_at].asc)
  end

  def discipline_content_record
    DisciplineContentRecord.by_unity_id(unity_id)
      .by_teacher_id(teacher_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_date_range(date_start.to_date, date_end.to_date)
      .ordered
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

  def must_have_records
    return unless errors.blank?

    if report_type == "1"
      if discipline_lesson_plan.count == 0
        errors.add(:discipline_lesson_plan, :must_have_discipline_lesson_plan)
      end
    else
      if discipline_content_record.count == 0
        errors.add(:discipline_lesson_plan, :must_have_discipline_lesson_plan)
      end
    end
  end
end
