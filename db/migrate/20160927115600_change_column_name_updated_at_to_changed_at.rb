class ChangeColumnNameUpdatedAtToChangedAt < ActiveRecord::Migration[4.2]
  def change
    rename_column :student_enrollments, :updated_at, :changed_at
    rename_column :student_enrollment_classrooms, :updated_at, :changed_at
  end
end
