class CreateStudentEnrollmentClassrooms < ActiveRecord::Migration[4.2]
  def change
    create_table :student_enrollment_classrooms do |t|
      t.string :api_code
      t.references :student_enrollment, index: true, foreign_key: true
      t.references :classroom, index: true, foreign_key: true
      t.string :classroom_code
      t.date :joined_at
      t.date :left_at
      t.timestamp :updated_at
      t.integer :sequence
    end
  end
end
