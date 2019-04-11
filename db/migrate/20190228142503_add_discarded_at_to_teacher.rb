class AddDiscardedAtToTeacher < ActiveRecord::Migration
  def change
    add_column :teachers, :discarded_at, :datetime
    add_index :teachers, :discarded_at
  end
end
