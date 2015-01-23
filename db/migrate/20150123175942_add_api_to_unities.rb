class AddApiToUnities < ActiveRecord::Migration
  def change
    add_column :unities, :api, :boolean, default: false
  end
end
