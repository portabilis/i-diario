class AddLegendToSchoolCalendarEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_events, :legend, :string, limit: 1
  end
end
