class AddTypeOfTeachingToStudentEnrollmentClassrooms < ActiveRecord::Migration
  def change
    add_column :student_enrollment_classrooms, :type_of_teaching, :integer, default: 1
  end
end
