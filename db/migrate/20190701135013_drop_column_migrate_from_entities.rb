class DropColumnMigrateFromEntities < ActiveRecord::Migration[4.2]
  def change
    remove_column :entities, :migrate, :boolean
  end
end
