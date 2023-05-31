class AddColumnMetaDataToWorkerStates < ActiveRecord::Migration[4.2]
  def change
    add_column :worker_states, :meta_data, :json, null: false, default: '{}'
  end
end
