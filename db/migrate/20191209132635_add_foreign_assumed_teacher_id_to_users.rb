class AddForeignAssumedTeacherIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :users, :teachers, column: :assumed_teacher_id
  end
end
