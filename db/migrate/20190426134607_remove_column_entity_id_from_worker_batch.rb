class RemoveColumnEntityIdFromWorkerBatch < ActiveRecord::Migration
  def change
    remove_column :worker_batches, :entity_id, :integer
  end
end
