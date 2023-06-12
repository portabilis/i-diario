class FillRecordedAtToTranferNotes < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE transfer_notes SET recorded_at = transfer_date;
    SQL
  end
end
