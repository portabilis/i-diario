class AddUnityIdToSchoolCalendars < ActiveRecord::Migration
  def change
    add_reference(:school_calendars, :unity, index: true, foreign_key: true)
  end
end
