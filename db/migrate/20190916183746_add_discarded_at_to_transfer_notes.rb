class AddDiscardedAtToTransferNotes < ActiveRecord::Migration
  def change
    add_column :transfer_notes, :discarded_at, :datetime
  end
end
