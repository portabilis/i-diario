class AddMigrateToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :migrate, :boolean, null: false, default: true
  end
end
