class AddNotNullToSchoolCalendarClassroomsClassroomId < ActiveRecord::Migration
  def change
    change_column_null :school_calendar_classrooms, :classroom_id, false
  end
end
