class AddExactDecimalPlaceToRoundingTableValues < ActiveRecord::Migration[4.2]
  def change
    add_column :rounding_table_values, :exact_decimal_place, :integer
  end
end
