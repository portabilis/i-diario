class DropColumnMigrateFromEntities < ActiveRecord::Migration
  def change
    remove_column :entities, :migrate, :boolean
  end
end
