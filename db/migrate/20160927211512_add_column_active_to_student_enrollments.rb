class AddColumnActiveToStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollments, :active, :integer
  end
end
