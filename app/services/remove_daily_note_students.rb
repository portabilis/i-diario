class RemoveDailyNoteStudents

  def self.call(joined_at, left_at, student_id, classroom_id)
    new(joined_at, left_at, student_id, classroom_id).call
  end

  def initialize(joined_at, left_at, student_id, classroom_id)
    @joined_at = joined_at
    @left_at = left_at
    @student_id = student_id
    @classroom_id = classroom_id
  end

  def call
    avaliations = Avaliation.by_classroom_id(classroom_id).pluck(:id, :test_date).to_h
    daily_note_ids = DailyNote.where(avaliation_id: avaliations.keys).pluck(:id)
    daily_note_students = DailyNoteStudent.with_discarded.where(daily_note_id: daily_note_ids, student_id: student_id)

    daily_note_students.each do |daily_note_student|
      avaliation_id = daily_note_student.daily_note.avaliation_id
      @date_avaliation = avaliations[avaliation_id].to_date

      next if daily_note_student.note.present? || daily_note_student.transfer_note_id.present?

      daily_note_student.discard_or_undiscard(student_inactive_in_date?)
      daily_note_student.active = !student_inactive_in_date?
    end
  end

  def student_inactive_in_date?
    @date_avaliation < joined_at.to_date || @date_avaliation >= left_at.to_date
  end

  private

  attr_accessor :classroom_id, :student_id, :left_at, :joined_at
end
