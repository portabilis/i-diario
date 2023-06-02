class RemoveColumnClassroomApiCodeFromSchoolCalendarClassrooms < ActiveRecord::Migration[4.2]
  def change
    remove_column :school_calendar_classrooms, :classroom_api_code
  end
end
