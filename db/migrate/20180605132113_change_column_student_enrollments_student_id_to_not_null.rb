class ChangeColumnStudentEnrollmentsStudentIdToNotNull < ActiveRecord::Migration
  def change
    change_column_null :student_enrollments, :student_id, false
  end
end
