class AddUniqueIndexToSchoolCalendars < ActiveRecord::Migration
  def change
    add_index :school_calendars, [:year, :unity_id], unique: true
  end
end
