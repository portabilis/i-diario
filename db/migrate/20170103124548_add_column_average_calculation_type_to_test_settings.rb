class AddColumnAverageCalculationTypeToTestSettings < ActiveRecord::Migration
  def change
    add_column :test_settings, :average_calculation_type, :string
  end
end
