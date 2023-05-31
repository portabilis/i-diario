class AddDeletedAtToDailyNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_notes, :deleted_at, :datetime
    add_index :daily_notes, :deleted_at
  end
end
