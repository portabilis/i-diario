class AddCourseToSchoolCalendarEvents < ActiveRecord::Migration[4.2]
  def change
    add_reference :school_calendar_events, :course, index: true, foreign_key: true
  end
end
