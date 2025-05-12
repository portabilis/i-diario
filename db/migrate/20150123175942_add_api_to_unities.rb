class AddApiToUnities < ActiveRecord::Migration[4.2]
  def change
    add_column :unities, :api, :boolean, default: false
  end
end
