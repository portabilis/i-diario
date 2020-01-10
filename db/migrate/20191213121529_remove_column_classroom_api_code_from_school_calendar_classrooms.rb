class RemoveColumnClassroomApiCodeFromSchoolCalendarClassrooms < ActiveRecord::Migration
  def change
    remove_column :school_calendar_classrooms, :classroom_api_code
  end
end
