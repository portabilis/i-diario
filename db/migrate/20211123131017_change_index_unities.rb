class ChangeIndexUnities < ActiveRecord::Migration
  def change
    remove_index :unities, :name
    add_index :unities, :name, unique: false
  end
end
