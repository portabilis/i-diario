class AddUniqueTeacherIdIdxToUsers < ActiveRecord::Migration[4.2]
  def up
    add_index :users, :teacher_id, unique: true, name: :unique_index_users_on_teacher_id
    remove_index :users, name: :index_users_on_teacher_id
  end

  def down
    remove_index :users, name: :unique_index_users_on_teacher_id
    add_index :users, :teacher_id
  end
end
