class FillRecordedAtToTranferNotes < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE transfer_notes SET recorded_at = transfer_date;
    SQL
  end
end
