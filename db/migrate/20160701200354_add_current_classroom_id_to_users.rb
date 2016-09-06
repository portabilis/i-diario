class AddCurrentClassroomIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_classroom_id, :integer
  end
end
