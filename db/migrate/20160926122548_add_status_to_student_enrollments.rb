class AddStatusToStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollments, :status, :integer
  end
end
