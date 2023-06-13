class CreateAndRenameRoundingTablesAndRoundingTableValues < ActiveRecord::Migration[4.2]
  def change
    rename_table :rounding_tables, :rounding_table_values
    rename_column :rounding_table_values, :api_code, :tabela_arredondamento_id

    create_table :rounding_tables do |t|
      t.string :api_code
      t.string :name

      t.timestamps
    end

    add_column :rounding_table_values, :rounding_table_id, :integer
    add_index :rounding_table_values, :rounding_table_id
    add_foreign_key :rounding_table_values, :rounding_tables
  end
end
