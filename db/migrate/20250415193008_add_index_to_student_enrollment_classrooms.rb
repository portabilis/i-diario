class AddIndexToStudentEnrollmentClassrooms < ActiveRecord::Migration[5.0]
  def change
    add_index :student_enrollment_classrooms,
              [:api_code, :student_enrollment_id, :classrooms_grade_id, :joined_at, :left_at],
              name: 'index_student_enrollment_classrooms_on_multiple_columns',
              unique: true
  end
end
