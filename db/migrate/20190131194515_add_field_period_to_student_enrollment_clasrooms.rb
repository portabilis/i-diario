class AddFieldPeriodToStudentEnrollmentClasrooms < ActiveRecord::Migration
  def change
    add_column :student_enrollment_classrooms, :period, :integer
  end
end
