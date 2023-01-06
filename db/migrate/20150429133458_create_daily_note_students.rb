class CreateDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :daily_note_students do |t|
      t.references :daily_note, index: true, null: false
      t.references :student, index: true, null: false
      t.decimal :note, null: false

      t.timestamps
    end

    add_foreign_key :daily_note_students, :daily_notes
    add_foreign_key :daily_note_students, :students
  end
end
