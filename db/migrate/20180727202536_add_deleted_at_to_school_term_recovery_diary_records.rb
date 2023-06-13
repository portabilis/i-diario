class AddDeletedAtToSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    add_column :school_term_recovery_diary_records, :deleted_at, :datetime
    add_index :school_term_recovery_diary_records, :deleted_at
  end
end
