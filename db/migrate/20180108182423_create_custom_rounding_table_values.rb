class CreateCustomRoundingTableValues < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_rounding_table_values do |t|
      t.references :custom_rounding_table, index: true, foreign_key: true
      t.string :label
      t.integer :action
      t.integer :exact_decimal_place

      t.timestamps null: false
    end
  end
end
