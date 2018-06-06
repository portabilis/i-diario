class AddTimestampsToStudentEnrollments < ActiveRecord::Migration
  def change
    add_timestamps(:student_enrollments)
  end
end
