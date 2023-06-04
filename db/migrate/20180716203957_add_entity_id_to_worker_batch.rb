class AddEntityIdToWorkerBatch < ActiveRecord::Migration[4.2]
  def change
    add_column :worker_batches, :entity_id, :integer
  end
end
