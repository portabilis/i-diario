class AddRecordedAtToSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration
  def change
    add_column :school_term_recovery_diary_records, :recorded_at, :date
  end
end
