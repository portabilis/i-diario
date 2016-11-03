class RemoveColumnDependenceOnStudentEnrollment < ActiveRecord::Migration
  def change
    remove_column :student_enrollments, :dependence
  end
end
