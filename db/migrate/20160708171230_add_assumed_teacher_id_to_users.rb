class AddAssumedTeacherIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :assumed_teacher_id, :integer
  end
end
