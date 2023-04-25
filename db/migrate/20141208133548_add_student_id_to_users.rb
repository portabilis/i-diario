class AddStudentIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :student_id, :integer
    add_index :users, :student_id
    add_foreign_key :users, :students
  end
end
