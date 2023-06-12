class RemoveActiveFromSchoolCalendarSteps < ActiveRecord::Migration[4.2]
  def change
    remove_column :school_calendar_steps, :active, :boolean
  end
end
