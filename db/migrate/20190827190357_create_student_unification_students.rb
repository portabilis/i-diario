class CreateStudentUnificationStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :student_unification_students do |t|
      t.belongs_to :student_unification
      t.belongs_to :student
      t.timestamps
    end
  end
end
