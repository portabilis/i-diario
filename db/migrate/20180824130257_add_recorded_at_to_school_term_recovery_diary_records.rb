class AddRecordedAtToSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration[4.2]
  def change
    add_column :school_term_recovery_diary_records, :recorded_at, :date
  end
end
