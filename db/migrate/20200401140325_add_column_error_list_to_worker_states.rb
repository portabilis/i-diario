class AddColumnErrorListToWorkerStates < ActiveRecord::Migration[4.2]
  def change
    add_column :worker_states, :error_list, :text, array: true, default: []
  end
end
