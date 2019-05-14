class AddDiscardedAtToObservationDiaryRecord < ActiveRecord::Migration
  def change
    add_column :observation_diary_records, :discarded_at, :datetime
    add_index :observation_diary_records, :discarded_at
  end
end
