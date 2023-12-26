class AddDiscardedAtToSpecificStep < ActiveRecord::Migration[4.2]
  def up
    add_column :specific_steps, :discarded_at, :datetime
    add_index :specific_steps, :discarded_at
  end

  def down
    remove_column :specific_steps, :discarded_at
  end
end
