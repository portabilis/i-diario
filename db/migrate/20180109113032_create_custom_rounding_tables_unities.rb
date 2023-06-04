class CreateCustomRoundingTablesUnities < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_rounding_tables_unities, id: false do |t|
      t.belongs_to :custom_rounding_table
      t.belongs_to :unity
    end

    add_index :custom_rounding_tables_unities, :custom_rounding_table_id,
      name: 'idx_custom_rounding_tables_unities_on_custom_rounding_table_id'
    add_index :custom_rounding_tables_unities, :unity_id,
      name: 'idx_custom_rounding_tables_unities_on_unity_id'
  end
end
