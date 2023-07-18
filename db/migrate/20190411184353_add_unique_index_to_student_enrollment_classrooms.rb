class AddUniqueIndexToStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_index :student_enrollment_classrooms,
              [:student_enrollment_id, :classroom_id, :joined_at, :period],
              name: 'student_enrollment_classrooms_unique_index',
              unique: true
  end
end
