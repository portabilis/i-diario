class CreateContentRecords < ActiveRecord::Migration[4.2]
  def change
    create_table :content_records do |t|
      t.integer :classroom_id, null: false, index: true
      t.integer :teacher_id, null: false, index: true
      t.date :record_date, null: false

      t.timestamps
    end
    add_foreign_key :content_records, :classrooms
    add_foreign_key :content_records, :teachers
  end
end
