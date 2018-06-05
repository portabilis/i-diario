class AddActiveToSchoolCalendarClassroomSteps < ActiveRecord::Migration
  def change
    add_column :school_calendar_classroom_steps, :active, :boolean, default: true
  end
end
