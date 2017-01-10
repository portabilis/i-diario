class ChangeTransferNotesToAcceptNullOnSchoolCalendarStepId < ActiveRecord::Migration
  def change
    change_column :transfer_notes, :school_calendar_step_id, :integer, null: true
  end
end
