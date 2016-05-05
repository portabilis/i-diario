class AddActionToRoundingTableValues < ActiveRecord::Migration
  def change
    add_column :rounding_table_values, :action, :integer
  end
end
