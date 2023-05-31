class RemoveColumnEntityIdFromWorkerBatch < ActiveRecord::Migration[4.2]
  def change
    remove_column :worker_batches, :entity_id, :integer
  end
end
