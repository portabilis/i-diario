class AddDiscardedAtToCourse < ActiveRecord::Migration[4.2]
  def up
    add_column :courses, :discarded_at, :datetime
    add_index :courses, :discarded_at
  end

  def down
    remove_column :courses, :discarded_at
  end
end
