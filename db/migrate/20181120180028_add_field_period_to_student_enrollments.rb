class AddFieldPeriodToStudentEnrollments < ActiveRecord::Migration
  def change
    add_column :student_enrollments, :period, :integer
  end
end
