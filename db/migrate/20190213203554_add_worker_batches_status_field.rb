class AddWorkerBatchesStatusField < ActiveRecord::Migration[4.2]
  def change
    add_column :worker_batches, :status, :string
  end
end
