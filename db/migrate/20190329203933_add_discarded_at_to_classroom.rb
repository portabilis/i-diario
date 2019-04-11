class AddDiscardedAtToClassroom < ActiveRecord::Migration
  def change
    add_column :classrooms, :discarded_at, :datetime
    add_index :classrooms, :discarded_at
  end
end
