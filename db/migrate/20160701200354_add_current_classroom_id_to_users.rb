class AddCurrentClassroomIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_classroom_id, :integer
  end
end
