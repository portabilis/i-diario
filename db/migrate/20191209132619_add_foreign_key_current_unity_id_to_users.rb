class AddForeignKeyCurrentUnityIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :users, :unities, column: :current_unity_id
  end
end
