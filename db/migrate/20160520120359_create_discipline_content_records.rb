class CreateDisciplineContentRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :discipline_content_records do |t|
      t.integer :discipline_id, null: false, index: true
      t.integer :content_record_id, null: false, index: { unique: true }

      t.timestamps
    end
    add_foreign_key :discipline_content_records, :content_records
    add_foreign_key :discipline_content_records, :disciplines
  end
end
