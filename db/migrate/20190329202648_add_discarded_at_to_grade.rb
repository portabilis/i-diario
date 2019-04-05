class AddDiscardedAtToGrade < ActiveRecord::Migration
  def change
    add_column :grades, :discarded_at, :datetime
    add_index :grades, :discarded_at
  end
end
