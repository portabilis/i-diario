class UpdateNullActiveFieldOnDailyNoteStudent < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE daily_note_students
         SET active = transfer_note_id is not null
       WHERE active is null
    SQL
  end
end
