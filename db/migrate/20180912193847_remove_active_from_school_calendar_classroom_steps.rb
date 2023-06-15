class RemoveActiveFromSchoolCalendarClassroomSteps < ActiveRecord::Migration[4.2]
  def change
    remove_column :school_calendar_classroom_steps, :active, :boolean
  end
end
