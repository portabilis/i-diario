class AddDeletedAtToTransferNotes < ActiveRecord::Migration
  def change
    add_column :transfer_notes, :deleted_at, :datetime
    add_index :transfer_notes, :deleted_at
  end
end
