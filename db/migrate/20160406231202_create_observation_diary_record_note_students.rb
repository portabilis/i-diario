class CreateObservationDiaryRecordNoteStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :observation_diary_record_note_students do |t|
      t.references :observation_diary_record_note, null: false
      t.references :student, null: false, index: true, foreign_key: true

      t.timestamps null: false
    end

    add_index(
      :observation_diary_record_note_students,
      :observation_diary_record_note_id,
      name: :idx_observdiaryrecordnotestudents_on_observationdiaryrecordnote
    )

    add_foreign_key(
      :observation_diary_record_note_students,
      :observation_diary_record_notes,
      name: :obs_diary_record_note_students_observat_diary_record_note_id_fk
    )

    add_index(
      :observation_diary_record_note_students,
      [:observation_diary_record_note_id, :student_id],
      unique: :true,
      name: :idx_obsdiaryrec_note_students_on_obs_diary_rec_note_and_student
    )
  end
end
