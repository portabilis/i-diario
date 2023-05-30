class AddColumnOpenedYearToSchoolCalendars < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendars, :opened_year, :boolean, null: false, default: false
  end
end
