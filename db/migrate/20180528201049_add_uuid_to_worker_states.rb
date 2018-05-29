class AddUuidToWorkerStates < ActiveRecord::Migration
  def change
    add_column :worker_states, :uuid, :string
  end
end
