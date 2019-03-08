class AddJobIndexToWorkerBatches < ActiveRecord::Migration
  def change
    add_index :worker_batches, [:main_job_class, :main_job_id]
  end
end
