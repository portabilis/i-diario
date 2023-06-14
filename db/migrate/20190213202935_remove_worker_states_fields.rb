class RemoveWorkerStatesFields < ActiveRecord::Migration[4.2]
  def change
    remove_column :worker_states, :user_id
    remove_column :worker_states, :job_id
    remove_column :worker_states, :uuid
  end
end
