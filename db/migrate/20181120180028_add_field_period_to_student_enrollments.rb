class AddFieldPeriodToStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollments, :period, :integer
  end
end
