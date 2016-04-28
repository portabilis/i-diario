class ObservationRecordReportQuery
  def initialize(teacher_id, classroom_id, discipline_id, start_at, end_at)
    @teacher_id = teacher_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
    @start_at = start_at.to_date
    @end_at = end_at.to_date
  end

  def observation_diary_records
    relation = ObservationDiaryRecord.includes(notes: :students)
      .by_teacher(teacher_id)
      .by_classroom(classroom_id)
      .where(date: start_at..end_at)
      .order(:date)

    relation = relation.by_discipline(discipline_id) if discipline_id.present?

    relation
  end

  private

  attr_accessor :teacher_id, :classroom_id, :discipline_id, :start_at, :end_at
end
