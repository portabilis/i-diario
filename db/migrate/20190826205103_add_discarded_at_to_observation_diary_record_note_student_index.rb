class AddDiscardedAtToObservationDiaryRecordNoteStudentIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index :observation_diary_record_note_students,
                 name: 'idx_obsdiaryrec_note_students_on_obs_diary_rec_note_and_student'

    add_index :observation_diary_record_note_students,
              [:observation_diary_record_note_id, :student_id, :discarded_at],
              unique: true,
              name: 'observation_diary_record_note_students_idx',
              where: 'discarded_at IS NULL'
  end
end
