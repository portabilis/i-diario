class CreateObservationDiaryRecordNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :observation_diary_record_notes do |t|
      t.references :observation_diary_record, null: false, foreign_key: true

      t.text :description, null: false

      t.timestamps null: false
    end

    add_index(
      :observation_diary_record_notes,
      :observation_diary_record_id,
      name: :idx_observation_diary_record_notes_on_observation_diary_record
    )
  end
end
