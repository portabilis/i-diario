class AddUnitTypeToUnities < ActiveRecord::Migration[4.2]
  def up
    add_column :unities, :unit_type, :string

    Unity.reset_column_information

    execute "update unities set unit_type = 'school_unit';"

    change_column :unities, :unit_type, :string, null: false
  end

  def down
    remove_column :unities, :unit_type
  end
end
