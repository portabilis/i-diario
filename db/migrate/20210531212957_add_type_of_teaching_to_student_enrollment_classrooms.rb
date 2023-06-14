class AddTypeOfTeachingToStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollment_classrooms, :type_of_teaching, :integer, default: 1
  end
end
