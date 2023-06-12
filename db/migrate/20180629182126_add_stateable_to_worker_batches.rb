class AddStateableToWorkerBatches < ActiveRecord::Migration[4.2]
  def change
    add_reference :worker_batches, :stateable, polymorphic: true, index: true
  end
end
