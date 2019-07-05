class AddDiscardedAtToAbsenceJustification < ActiveRecord::Migration
  def up
    add_column :absence_justifications, :discarded_at, :datetime
    add_index :absence_justifications, :discarded_at
  end

  def down
    remove_column :absence_justifications, :discarded_at
  end
end
