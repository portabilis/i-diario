class AddExactDecimalPlaceToRoundingTableValues < ActiveRecord::Migration
  def change
    add_column :rounding_table_values, :exact_decimal_place, :integer
  end
end
