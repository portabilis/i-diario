class RemoveUnityIdFromAvaliations < ActiveRecord::Migration[4.2]
  def change
    remove_column :avaliations, :unity_id
  end
end
