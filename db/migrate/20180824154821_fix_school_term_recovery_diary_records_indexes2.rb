class FixSchoolTermRecoveryDiaryRecordsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :school_term_recovery_diary_records, name: :idx_school_term_recov_diary_records_on_recovery_diary_record_id, algorithm: :concurrently
    remove_index :school_term_recovery_diary_records, name: :idx_school_term_recove_diary_records_on_school_calendar_step_id, algorithm: :concurrently
    remove_index :school_term_recovery_diary_records, name: :index_on_recovery_diary_record_id_and_school_calendar_step_id, unique: true, algorithm: :concurrently
    remove_index :school_term_recovery_diary_records, name: :index_school_calendar_classroom_step_id, algorithm: :concurrently

    add_index :school_term_recovery_diary_records, :recovery_diary_record_id, name: :idx_school_term_recov_diary_records_on_recovery_diary_record_id, algorithm: :concurrently
    add_index :school_term_recovery_diary_records, :school_calendar_step_id, name: :idx_school_term_recove_diary_records_on_school_calendar_step_id, algorithm: :concurrently
    add_index :school_term_recovery_diary_records, [:recovery_diary_record_id, :school_calendar_step_id], name: :index_on_recovery_diary_record_id_and_school_calendar_step_id, unique: true, algorithm: :concurrently
    add_index :school_term_recovery_diary_records, :school_calendar_classroom_step_id, name: :index_school_calendar_classroom_step_id, algorithm: :concurrently
  end
end
