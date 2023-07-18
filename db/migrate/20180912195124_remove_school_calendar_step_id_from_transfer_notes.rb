class RemoveSchoolCalendarStepIdFromTransferNotes < ActiveRecord::Migration[4.2]
  def change
    remove_column :transfer_notes, :school_calendar_step_id, :integer
  end
end
