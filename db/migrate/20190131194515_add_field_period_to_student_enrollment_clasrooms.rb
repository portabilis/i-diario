class AddFieldPeriodToStudentEnrollmentClasrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollment_classrooms, :period, :integer
  end
end
