class AddStartedAndEndedToWorkerStates < ActiveRecord::Migration[4.2]
  def change
    add_column :worker_states, :started_at, :datetime
    add_column :worker_states, :ended_at, :datetime
  end
end
