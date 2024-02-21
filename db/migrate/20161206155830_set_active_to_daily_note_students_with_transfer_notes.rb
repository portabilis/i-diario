class SetActiveToDailyNoteStudentsWithTransferNotes < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE daily_note_students set active = 't' WHERE transfer_note_id IS NOT NULL;
    SQL
  end
end
