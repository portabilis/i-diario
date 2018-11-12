class AddUniqueIndexDailyNoteStudentsWhereActive < ActiveRecord::Migration
  def change
    add_index :daily_note_students, [:daily_note_id, :student_id], unique: true, where: "active"
  end
end
