class AddStartedAndEndedToWorkerStates < ActiveRecord::Migration
  def change
    add_column :worker_states, :started_at, :datetime
    add_column :worker_states, :ended_at, :datetime
  end
end
