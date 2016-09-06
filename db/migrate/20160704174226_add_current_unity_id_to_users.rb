class AddCurrentUnityIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_unity_id, :integer
  end
end
