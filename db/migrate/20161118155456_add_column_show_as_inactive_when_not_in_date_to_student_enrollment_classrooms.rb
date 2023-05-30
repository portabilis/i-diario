class AddColumnShowAsInactiveWhenNotInDateToStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :student_enrollment_classrooms, :show_as_inactive_when_not_in_date, :boolean
  end
end
