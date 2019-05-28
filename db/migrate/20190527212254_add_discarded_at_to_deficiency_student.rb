class AddDiscardedAtToDeficiencyStudent < ActiveRecord::Migration
  def change
    add_column :deficiency_students, :discarded_at, :datetime
    add_index :deficiency_students, :discarded_at
  end
end
