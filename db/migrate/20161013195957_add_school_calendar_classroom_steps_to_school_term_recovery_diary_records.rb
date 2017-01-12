class AddSchoolCalendarClassroomStepsToSchoolTermRecoveryDiaryRecords < ActiveRecord::Migration
  def change
    add_reference :school_term_recovery_diary_records, :school_calendar_classroom_step, index: { name: "index_school_calendar_classroom_step_id" }
  end
end
