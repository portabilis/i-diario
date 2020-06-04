class AddShowInFrequencyRecordToSchoolCalendarEvents < ActiveRecord::Migration
  def change
    add_column :school_calendar_events, :show_in_frequency_record, :boolean, default: false
  end
end
