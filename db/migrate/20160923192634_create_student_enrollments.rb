class CreateStudentEnrollments < ActiveRecord::Migration[4.2]
  def change
    create_table :student_enrollments do |t|
      t.string :api_code
      t.references :student, index: true, foreign_key: true
      t.string :student_code
      t.boolean :dependence
      t.timestamp :updated_at
    end
  end
end
