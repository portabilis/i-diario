class ResetChangedAtInStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE student_enrollment_classrooms SET changed_at = '2000-01-01';
    SQL
  end
end
