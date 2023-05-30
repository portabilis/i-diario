class AddDisabledToEntity < ActiveRecord::Migration[4.2]
  def change
    add_column :entities, :disabled, :boolean, default: false
  end
end
