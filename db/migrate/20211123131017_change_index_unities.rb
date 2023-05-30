class ChangeIndexUnities < ActiveRecord::Migration[4.2]
  def change
    remove_index :unities, :name
    add_index :unities, :name, unique: false
  end
end
