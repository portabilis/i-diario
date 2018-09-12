class RemoveSchoolCalendarClassroomStepIdFromTransferNotes < ActiveRecord::Migration
  def change
    remove_column :transfer_notes, :school_calendar_classroom_step_id, :integer
  end
end
