class FixDailyNotesIndexes < ActiveRecord::Migration
  def change
    remove_index :daily_notes, :avaliation_id

    add_index :daily_notes, :avaliation_id, where: "deleted_at IS NULL"
  end
end
