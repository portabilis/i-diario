class AddForeignKeyCurrentUnityIdToUsers < ActiveRecord::Migration
  def change
    add_foreign_key :users, :unities, column: :current_unity_id
  end
end
