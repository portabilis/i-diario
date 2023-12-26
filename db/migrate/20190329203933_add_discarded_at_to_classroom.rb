class AddDiscardedAtToClassroom < ActiveRecord::Migration[4.2]
  def up
    add_column :classrooms, :discarded_at, :datetime
    add_index :classrooms, :discarded_at
  end

  def down
    remove_column :classrooms, :discarded_at
  end
end
