class AddUuidToWorkerStates < ActiveRecord::Migration[4.2]
  def change
    add_column :worker_states, :uuid, :string
    add_index :worker_states, [:kind, :uuid, :status], name: 'worker_states_unique_index_to_kind_uuid_status_started',
      unique: true, where: "status = 'started'"
  end
end
