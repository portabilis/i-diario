class DropColumnErrorMessageFromWorkerStates < ActiveRecord::Migration
  def change
    remove_column :worker_states, :error_message
  end
end
