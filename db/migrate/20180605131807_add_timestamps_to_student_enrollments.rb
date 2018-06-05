class AddTimestampsToStudentEnrollments < ActiveRecord::Migration
  def change
    add_timestamps(:student_enrollments, null: false, default: Time.now)
  end
end
