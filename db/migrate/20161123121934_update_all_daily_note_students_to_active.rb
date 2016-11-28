class UpdateAllDailyNoteStudentsToActive < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE daily_note_students set active = 't';
    SQL
  end
end
