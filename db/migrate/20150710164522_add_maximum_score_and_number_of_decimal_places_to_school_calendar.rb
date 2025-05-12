class AddMaximumScoreAndNumberOfDecimalPlacesToSchoolCalendar < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendars, :maximum_score, :integer, default: 10
    add_column :school_calendars, :number_of_decimal_places, :integer, default: 2

    execute <<-SQL
      UPDATE school_calendars SET maximum_score = 10 WHERE maximum_score IS NULL;
      UPDATE school_calendars SET number_of_decimal_places = 2 WHERE number_of_decimal_places IS NULL;
    SQL
  end
end
