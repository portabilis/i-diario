class RemoveColumnDependenceFromDailyNoteStudents < ActiveRecord::Migration[4.2]
  def change
    remove_column :daily_note_students, :dependence, :boolean
  end
end
