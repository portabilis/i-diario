class AddWorkerBatchIdToWorkerStates < ActiveRecord::Migration
  def change
    add_reference :worker_states, :worker_batch, index: true, foreign_key: true
  end
end
