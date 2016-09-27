class ChangeDateColumnsOnStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    change_column :student_enrollment_classrooms, :joined_at, :string
    change_column :student_enrollment_classrooms, :left_at, :string
    change_column :student_enrollment_classrooms, :updated_at, :string
  end
end
