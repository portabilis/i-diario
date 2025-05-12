class AddDiscardedAtToObservationDiaryRecord < ActiveRecord::Migration[4.2]
  def up
    add_column :observation_diary_records, :discarded_at, :datetime
    add_index :observation_diary_records, :discarded_at
  end

  def down
    remove_column :observation_diary_records, :discarded_at
  end
end
