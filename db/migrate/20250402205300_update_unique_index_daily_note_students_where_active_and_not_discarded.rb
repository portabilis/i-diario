class UpdateUniqueIndexDailyNoteStudentsWhereActiveAndNotDiscarded < ActiveRecord::Migration[5.0]
  def up
    remove_index :daily_note_students, [:daily_note_id, :student_id]

    add_index :daily_note_students,
              [:daily_note_id, :student_id],
              unique: true,
              where: "active AND discarded_at IS NULL",
              name: 'idx_unique_daily_note_students_active_not_discarded'
  end

  def down
    remove_index :daily_note_students, name: 'idx_unique_daily_note_students_active_not_discarded'

    add_index :daily_note_students, [:daily_note_id, :student_id], unique: true, where: "active"
  end
end