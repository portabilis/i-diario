class AddPeriodsToSchoolCalendarEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_events, :periods, :string, array: true, default: Periods.list
  end
end
