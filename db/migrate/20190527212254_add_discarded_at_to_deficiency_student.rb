class AddDiscardedAtToDeficiencyStudent < ActiveRecord::Migration[4.2]
  def up
    add_column :deficiency_students, :discarded_at, :datetime
    add_index :deficiency_students, :discarded_at
  end

  def down
    remove_column :deficiency_students, :discarded_at
  end
end
