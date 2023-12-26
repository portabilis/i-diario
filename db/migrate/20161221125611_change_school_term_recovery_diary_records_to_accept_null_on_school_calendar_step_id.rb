class ChangeSchoolTermRecoveryDiaryRecordsToAcceptNullOnSchoolCalendarStepId < ActiveRecord::Migration[4.2]
  def change
    change_column :school_term_recovery_diary_records, :school_calendar_step_id, :integer, null: true
  end
end
