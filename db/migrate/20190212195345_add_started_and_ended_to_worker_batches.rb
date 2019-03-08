class AddStartedAndEndedToWorkerBatches < ActiveRecord::Migration
  def change
    add_column :worker_batches, :started_at, :datetime
    add_column :worker_batches, :ended_at, :datetime
  end
end
