class AddRecordedAtToTransferNotes < ActiveRecord::Migration
  def change
    add_column :transfer_notes, :recorded_at, :date
  end
end
