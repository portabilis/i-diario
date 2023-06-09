class ChangeColumnUpdatedAtToStringOnStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    change_column :student_enrollments, :updated_at, :string
  end
end
