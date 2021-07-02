class AddDiscardToUnities < ActiveRecord::Migration
  def change
    add_column :unities, :discarded_at, :datetime
    add_index :unities, :discarded_at
  end
end
