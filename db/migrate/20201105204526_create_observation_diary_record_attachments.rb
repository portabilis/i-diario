class CreateObservationDiaryRecordAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :observation_diary_record_attachments do |t|
      t.references(
        :observation_diary_record,
        null: false,
        index: { name: 'index_attachments_on_observation_diary_record_id' }
      )
      t.string :attachment
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.string :attachment_file_name_with_hash

      t.timestamps null: false
    end

    add_foreign_key(
      :observation_diary_record_attachments,
      :observation_diary_records,
      name: 'fk_observation_diary_record_id'
    )
  end
end
