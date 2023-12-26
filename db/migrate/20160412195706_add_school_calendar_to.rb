class AddSchoolCalendarTo < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      update absence_justifications
        set school_calendar_id = (select school_calendars.id
                                    from school_calendars
                                  inner join classrooms on(absence_justifications.classroom_id = classrooms.id)
                                    where school_calendars.unity_id = absence_justifications.unity_id
                                      and school_calendars.year = classrooms.year)
                                    where absence_justifications.classroom_id is not null
    SQL
  end
end
