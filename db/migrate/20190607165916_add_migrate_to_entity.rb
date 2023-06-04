class AddMigrateToEntity < ActiveRecord::Migration[4.2]
  def change
    add_column :entities, :migrate, :boolean, null: false, default: true
  end
end
