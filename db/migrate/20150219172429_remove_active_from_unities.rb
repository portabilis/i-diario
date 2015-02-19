class RemoveActiveFromUnities < ActiveRecord::Migration
  def change
    remove_column :unities, :active
  end
end
