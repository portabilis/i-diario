class AddCourseToSchoolCalendarEvents < ActiveRecord::Migration
  def change
    add_reference :school_calendar_events, :course, index: true, foreign_key: true
  end
end
