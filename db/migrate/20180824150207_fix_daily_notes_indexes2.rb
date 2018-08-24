class FixDailyNotesIndexes2 < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    remove_index :daily_notes, column: [:avaliation_id], algorithm: :concurrently

    add_index :daily_notes, :avaliation_id, algorithm: :concurrently
  end
end
