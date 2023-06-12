class AddActiveToSchoolCalendarClassroomSteps < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_classroom_steps, :active, :boolean, default: true
  end
end
