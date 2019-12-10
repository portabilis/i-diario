class AddForeignAssumedTeacherIdToUsers < ActiveRecord::Migration
  def change
    add_foreign_key :users, :teachers, column: :assumed_teacher_id
  end
end
