class AddDiscardedAtToAvaliationExemption < ActiveRecord::Migration[4.2]
  def up
    add_column :avaliation_exemptions, :discarded_at, :datetime
    add_index :avaliation_exemptions, :discarded_at
  end

  def down
    remove_column :avaliation_exemptions, :discarded_at
  end
end
