class AddDeletedAtToRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    add_column :recovery_diary_records, :deleted_at, :datetime
    add_index :recovery_diary_records, :deleted_at
  end
end
