class AddColumnMetaDataToWorkerStates < ActiveRecord::Migration
  def change
    add_column :worker_states, :meta_data, :json, null: false, default: '{}'
  end
end
