class RemoveColumnDependenceFromDailyNoteStudents < ActiveRecord::Migration
  def change
    remove_column :daily_note_students, :dependence, :boolean
  end
end
