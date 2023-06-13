class CreateStudentEnrollmentDependences < ActiveRecord::Migration[4.2]
  def change
    create_table :student_enrollment_dependences do |t|
      t.integer :student_enrollment_id
      t.string :student_enrollment_code
      t.integer :discipline_id
      t.string :discipline_code
    end
  end
end
