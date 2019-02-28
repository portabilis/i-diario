class AddDiscardedAtToSpecificStep < ActiveRecord::Migration
  def change
    add_column :specific_steps, :discarded_at, :datetime
    add_index :specific_steps, :discarded_at
  end
end
