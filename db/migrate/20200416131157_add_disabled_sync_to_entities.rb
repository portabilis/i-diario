class AddDisabledSyncToEntities < ActiveRecord::Migration
  def change
    add_column :entities, :disabled_sync, :boolean, default: false
  end
end
