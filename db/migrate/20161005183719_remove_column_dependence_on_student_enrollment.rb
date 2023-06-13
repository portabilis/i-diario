class RemoveColumnDependenceOnStudentEnrollment < ActiveRecord::Migration[4.2]
  def change
    remove_column :student_enrollments, :dependence
  end
end
