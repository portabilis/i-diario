class AddDiscardedAtToTeachers < ActiveRecord::Migration[4.2]
  def up
    add_column :teachers, :discarded_at, :datetime
    add_index :teachers, :discarded_at
  end

  def down
    remove_column :teachers, :discarded_at
  end
end
