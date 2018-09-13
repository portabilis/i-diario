class RemoveSchoolCalendarClassroomStepIdFromSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration
  def change
    remove_column :school_term_recovery_diary_records, :school_calendar_classroom_step_id, :integer
  end
end
