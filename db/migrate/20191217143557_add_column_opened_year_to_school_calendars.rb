class AddColumnOpenedYearToSchoolCalendars < ActiveRecord::Migration
  def change
    add_column :school_calendars, :opened_year, :boolean, null: false, default: false
  end
end
