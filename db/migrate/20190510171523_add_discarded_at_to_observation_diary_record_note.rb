class AddDiscardedAtToObservationDiaryRecordNote < ActiveRecord::Migration
  def change
    add_column :observation_diary_record_notes, :discarded_at, :datetime
    add_index :observation_diary_record_notes, :discarded_at
  end
end
