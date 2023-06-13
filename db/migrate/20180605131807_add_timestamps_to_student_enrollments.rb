class AddTimestampsToStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:student_enrollments)
  end
end
