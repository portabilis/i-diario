class AddDiscardedAtToDeficiency < ActiveRecord::Migration[4.2]
  def up
    add_column :deficiencies, :discarded_at, :datetime
    add_index :deficiencies, :discarded_at
  end

  def down
    remove_column :deficiencies, :discarded_at
  end
end
