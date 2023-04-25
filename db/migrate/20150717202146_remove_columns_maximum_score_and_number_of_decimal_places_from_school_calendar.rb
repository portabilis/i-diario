class RemoveColumnsMaximumScoreAndNumberOfDecimalPlacesFromSchoolCalendar < ActiveRecord::Migration[4.2]
  def change
    remove_column :school_calendars, :maximum_score
    remove_column :school_calendars, :number_of_decimal_places
  end
end
