class UpdateNullActiveFieldOnDailyNoteStudent < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE daily_note_students
         SET active = true
       WHERE active is null
    SQL
  end
end
