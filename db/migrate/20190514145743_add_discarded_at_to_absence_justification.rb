class AddDiscardedAtToAbsenceJustification < ActiveRecord::Migration
  def change
    add_column :absence_justifications, :discarded_at, :datetime
    add_index :absence_justifications, :discarded_at
  end
end
