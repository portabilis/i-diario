class AddDiscardedAtToStudent < ActiveRecord::Migration
  def up
    add_column :students, :discarded_at, :datetime
    add_index :students, :discarded_at
  end

  def down
    remove_column :students, :discarded_at
  end
end
