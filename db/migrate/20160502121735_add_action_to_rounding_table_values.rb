class AddActionToRoundingTableValues < ActiveRecord::Migration[4.2]
  def change
    add_column :rounding_table_values, :action, :integer
  end
end
