class AddDiscardedAtToAvaliationExemption < ActiveRecord::Migration
  def change
    add_column :avaliation_exemptions, :discarded_at, :datetime
    add_index :avaliation_exemptions, :discarded_at
  end
end
