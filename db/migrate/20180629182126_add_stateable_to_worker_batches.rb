class AddStateableToWorkerBatches < ActiveRecord::Migration
  def change
    add_reference :worker_batches, :stateable, polymorphic: true, index: true
  end
end
