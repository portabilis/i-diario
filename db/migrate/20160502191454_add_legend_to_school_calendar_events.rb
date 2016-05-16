class AddLegendToSchoolCalendarEvents < ActiveRecord::Migration
  def change
    add_column :school_calendar_events, :legend, :string, limit: 1
  end
end
