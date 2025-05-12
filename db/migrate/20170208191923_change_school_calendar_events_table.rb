class ChangeSchoolCalendarEventsTable < ActiveRecord::Migration[4.2]
  def change
    rename_column :school_calendar_events, :event_date, :start_date
    add_column :school_calendar_events, :end_date, :date
    execute <<-SQL
      update school_calendar_events set end_date = start_date;
    SQL
  end
end
