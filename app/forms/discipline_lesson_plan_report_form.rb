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

  validates :date_start, presence: true, date: true, timeliness: { before: :date_end, type: :date, before_message: 'não pode ser maior que a Data final' }
  validates :date_end, presence: true, date: true, timeliness: { on_or_after: :date_start, type: :date, on_or_after_message: 'deve ser maior ou igual a Data inicial' }
  validates :unity_id,
    :classroom_id,
    :discipline_id,
    :teacher_id,
    presence: true

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
