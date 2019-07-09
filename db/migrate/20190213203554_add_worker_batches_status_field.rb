class AddWorkerBatchesStatusField < ActiveRecord::Migration
  def change
    add_column :worker_batches, :status, :string
  end
end
