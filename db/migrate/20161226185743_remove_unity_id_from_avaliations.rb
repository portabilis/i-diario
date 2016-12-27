class RemoveUnityIdFromAvaliations < ActiveRecord::Migration
  def change
    remove_column :avaliations, :unity_id
  end
end
