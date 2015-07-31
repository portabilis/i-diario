class AddDisabledToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :disabled, :boolean, default: false
  end
end
