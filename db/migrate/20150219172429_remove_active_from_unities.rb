class RemoveActiveFromUnities < ActiveRecord::Migration[4.2]
  def change
    remove_column :unities, :active
  end
end
