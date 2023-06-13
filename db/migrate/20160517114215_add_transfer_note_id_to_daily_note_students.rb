class AddTransferNoteIdToDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_note_students, :transfer_note_id, :integer, index: true
    add_foreign_key :daily_note_students, :transfer_notes
  end
end
