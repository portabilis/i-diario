class RemoveInvalidSchoolCalendarClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM school_calendar_classroom_steps WHERE school_calendar_classroom_id IN(SELECT id FROM school_calendar_classrooms WHERE classroom_id IS NULL);
      DELETE FROM school_calendar_classrooms WHERE classroom_id IS NULL;
    SQL
  end
end
