class RemoveActiveFromSchoolCalendarClassroomSteps < ActiveRecord::Migration
  def change
    remove_column :school_calendar_classroom_steps, :active, :boolean
  end
end
