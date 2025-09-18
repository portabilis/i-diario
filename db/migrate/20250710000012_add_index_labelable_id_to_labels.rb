class AddIndexLabelableIdToLabels < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :labels, :labelable_id, algorithm: :concurrently unless index_exists?(:labels, :labelable_id)
  end
  
  def down
    remove_index :labels, :labelable_id if index_exists?(:labels, :labelable_id)
  end
end