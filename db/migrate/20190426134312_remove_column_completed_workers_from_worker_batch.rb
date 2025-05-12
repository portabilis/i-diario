class RemoveColumnCompletedWorkersFromWorkerBatch < ActiveRecord::Migration[4.2]
  def up
    remove_column :worker_batches, :completed_workers
  end

  def down
    add_column :worker_batches, :completed_workers, :string, array: true, default: []
  end
end
