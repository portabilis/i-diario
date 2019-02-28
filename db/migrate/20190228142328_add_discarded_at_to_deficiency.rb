class AddDiscardedAtToDeficiency < ActiveRecord::Migration
  def change
    add_column :deficiencies, :discarded_at, :datetime
    add_index :deficiencies, :discarded_at
  end
end
