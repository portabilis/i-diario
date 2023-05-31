class RemoveColumnPeriodFromStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    remove_column :student_enrollments, :period, :integer
  end
end
