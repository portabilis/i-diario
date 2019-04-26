class RemoveColumnEntityIdFromWorkerBatch < ActiveRecord::Migration
  def up
    remove_column :worker_batches, :entity_id
  end

  def down
    add_column :worker_batches, :entity_id, :array, default: []
  end
end
