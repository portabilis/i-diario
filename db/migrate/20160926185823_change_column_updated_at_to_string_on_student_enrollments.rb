class ChangeColumnUpdatedAtToStringOnStudentEnrollments < ActiveRecord::Migration
  def change
    change_column :student_enrollments, :updated_at, :string
  end
end
