class AddStatusToStudentEnrollments < ActiveRecord::Migration
  def change
    add_column :student_enrollments, :status, :integer
  end
end
