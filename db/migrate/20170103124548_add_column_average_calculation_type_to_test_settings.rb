class AddColumnAverageCalculationTypeToTestSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :test_settings, :average_calculation_type, :string
  end
end
