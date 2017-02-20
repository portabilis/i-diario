class UpdateCourseIdOnSchoolCalendarEvents < ActiveRecord::Migration
  def change
    execute <<-SQL
    update school_calendar_events set course_id = (select course_id from grades where school_calendar_events.grade_id = grades.id) where coverage = 'by_classroom' or coverage = 'by_grade';
    SQL
  end
end
