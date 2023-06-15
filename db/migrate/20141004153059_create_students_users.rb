class CreateStudentsUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :students_users, id: false do |t|
      t.integer :student_id, null: false
      t.integer :user_id, null: false
    end
    add_index :students_users, [:student_id, :user_id], unique: true
    add_foreign_key :students_users, :students
    add_foreign_key :students_users, :users
  end
end
