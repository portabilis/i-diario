class AddColumnActiveToStudentEnrollments < ActiveRecord::Migration
  def change
    add_column :student_enrollments, :active, :integer
  end
end
