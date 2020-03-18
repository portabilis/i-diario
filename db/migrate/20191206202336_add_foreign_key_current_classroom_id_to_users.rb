class AddForeignKeyCurrentClassroomIdToUsers < ActiveRecord::Migration
  def change
    add_foreign_key :users, :classrooms, column: :current_classroom_id
  end
end
