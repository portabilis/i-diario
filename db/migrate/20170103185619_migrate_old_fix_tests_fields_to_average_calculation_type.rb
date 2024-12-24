class MigrateOldFixTestsFieldsToAverageCalculationType < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE test_settings SET average_calculation_type = (CASE WHEN test_settings.fix_tests = 't' THEN 'sum' ELSE 'arithmetic' END);
    SQL
  end
end
