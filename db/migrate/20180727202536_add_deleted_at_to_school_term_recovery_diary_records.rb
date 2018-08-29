class AddDeletedAtToSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration
  def change
    add_column :school_term_recovery_diary_records, :deleted_at, :datetime
    add_index :school_term_recovery_diary_records, :deleted_at
  end
end
