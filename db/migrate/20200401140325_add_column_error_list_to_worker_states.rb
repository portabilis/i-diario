class AddColumnErrorListToWorkerStates < ActiveRecord::Migration
  def change
    add_column :worker_states, :error_list, :text, array: true, default: []
  end
end
