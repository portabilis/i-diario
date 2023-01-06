class AddSchoolCalendarToDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_frequencies, :school_calendar_id, :integer, index: true, null: false
    add_foreign_key :daily_frequencies, :school_calendars
  end
end
