class AddAssumedTeacherIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :assumed_teacher_id, :integer
  end
end
