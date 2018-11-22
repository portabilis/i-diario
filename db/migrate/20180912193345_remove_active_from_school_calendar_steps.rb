class RemoveActiveFromSchoolCalendarSteps < ActiveRecord::Migration
  def change
    remove_column :school_calendar_steps, :active, :boolean
  end
end
