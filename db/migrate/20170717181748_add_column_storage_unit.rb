class AddColumnStorageUnit < ActiveRecord::Migration
  def change
    add_column :***REMOVED***, :storage_unit, :string, limit: 10
  end
end
