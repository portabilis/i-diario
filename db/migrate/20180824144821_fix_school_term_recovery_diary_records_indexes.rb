class FixSchoolTermRecoveryDiaryRecordsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :school_term_recovery_diary_records, name: :idx_school_term_recov_diary_records_on_recovery_diary_record_id
    remove_index :school_term_recovery_diary_records, name: :idx_school_term_recove_diary_records_on_school_calendar_step_id
    remove_index :school_term_recovery_diary_records, name: :index_on_recovery_diary_record_id_and_school_calendar_step_id
    remove_index :school_term_recovery_diary_records, name: :index_school_calendar_classroom_step_id

    add_index :school_term_recovery_diary_records, :recovery_diary_record_id, where: "deleted_at IS NULL", name: :idx_school_term_recov_diary_records_on_recovery_diary_record_id
    add_index :school_term_recovery_diary_records, :school_calendar_step_id, where: "deleted_at IS NULL", name: :idx_school_term_recove_diary_records_on_school_calendar_step_id
    add_index :school_term_recovery_diary_records, [:recovery_diary_record_id, :school_calendar_step_id], where: "deleted_at IS NULL", name: :index_on_recovery_diary_record_id_and_school_calendar_step_id, unique: true
    add_index :school_term_recovery_diary_records, :school_calendar_classroom_step_id, where: "deleted_at IS NULL", name: :index_school_calendar_classroom_step_id
  end
end
