class RenameColumnOnRoundingTableValues < ActiveRecord::Migration
  def change
    rename_column :rounding_table_values, :tabela_arredondamento_id, :rounding_table_api_code
  end
end
