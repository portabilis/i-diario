class ChangeTransferNotesToAcceptNullOnSchoolCalendarStepId < ActiveRecord::Migration[4.2]
  def change
    change_column :transfer_notes, :school_calendar_step_id, :integer, null: true
  end
end
