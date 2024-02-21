class AddCurrentUnityIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_unity_id, :integer
  end
end
