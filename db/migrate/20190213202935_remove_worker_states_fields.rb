class RemoveWorkerStatesFields < ActiveRecord::Migration
  def change
    remove_column :worker_states, :user_id
    remove_column :worker_states, :job_id
    remove_column :worker_states, :uuid
  end
end
