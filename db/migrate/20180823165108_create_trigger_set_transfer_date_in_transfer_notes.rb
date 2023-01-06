class CreateTriggerSetTransferDateInTransferNotes < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      CREATE TRIGGER trigger_set_transfer_date_in_transfer_notes
      BEFORE INSERT OR UPDATE ON transfer_notes
      FOR EACH ROW
      EXECUTE PROCEDURE set_transfer_date_in_transfer_notes();
    SQL
  end
end
