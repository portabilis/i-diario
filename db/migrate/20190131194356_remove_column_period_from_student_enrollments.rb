class RemoveColumnPeriodFromStudentEnrollments < ActiveRecord::Migration
  def change
    remove_column :student_enrollments, :period, :integer
  end
end
