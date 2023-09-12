class RemoveDailyNoteStudentsWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, joined_at, left_at, student_id, classroom_id)
    Entity.find(entity_id).using_connection do
      avaliations = Avaliation.by_classroom_id(classroom_id).pluck(:id, :test_date).to_h
      daily_note_ids = DailyNote.where(avaliation_id: avaliations.keys).pluck(:id)
      daily_note_students = DailyNoteStudent.where(daily_note_id: daily_note_ids, student_id: student_id)

      daily_note_students.each do |daily_note_student|
        avaliation_id = daily_note_student.daily_note.avaliation_id
        date_avaliation = avaliations[avaliation_id].to_date

        next if daily_note_student.value.present?

        daily_note_student.discard_or_undiscard(
          date_avaliation <= joined_at.to_date || date_avaliation >= left_at.to_date
        )
      end
    end
  end
end
