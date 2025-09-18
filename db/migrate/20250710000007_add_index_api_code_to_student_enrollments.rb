class AddIndexApiCodeToStudentEnrollments < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    add_index :student_enrollments, :api_code, algorithm: :concurrently unless index_exists?(:student_enrollments, :api_code)
  end
  
  def down
    remove_index :student_enrollments, :api_code if index_exists?(:student_enrollments, :api_code)
  end
end