class AddEntityIdToWorkerBatch < ActiveRecord::Migration
  def change
    add_column :worker_batches, :entity_id, :integer
  end
end
