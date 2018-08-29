class AddDeletedAtToDailyFrequencies < ActiveRecord::Migration
  def change
    add_column :daily_frequencies, :deleted_at, :datetime
    add_index :daily_frequencies, :deleted_at
  end
end
