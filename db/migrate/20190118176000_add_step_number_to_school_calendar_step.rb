class AddStepNumberToSchoolCalendarStep < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_steps, :step_number, :integer, null: false, default: 0
  end
end
