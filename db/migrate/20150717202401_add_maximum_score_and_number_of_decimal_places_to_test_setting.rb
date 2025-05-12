class AddMaximumScoreAndNumberOfDecimalPlacesToTestSetting < ActiveRecord::Migration[4.2]
  def change
    add_column :test_settings, :maximum_score, :integer, default: 10
    add_column :test_settings, :number_of_decimal_places, :integer, default: 2

    execute <<-SQL
      UPDATE test_settings SET maximum_score = 10 WHERE maximum_score IS NULL;
      UPDATE test_settings SET number_of_decimal_places = 2 WHERE number_of_decimal_places IS NULL;
    SQL
  end
end
