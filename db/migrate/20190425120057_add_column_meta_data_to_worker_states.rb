class AddColumnMetaDataToWorkerStates < ActiveRecord::Migration
  def change
    add_column :worker_states, :meta_data, :jsonb, null: false, default: '{}'
  end
end
