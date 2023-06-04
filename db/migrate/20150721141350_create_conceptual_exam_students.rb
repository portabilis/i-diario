class CreateConceptualExamStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :conceptual_exam_students do |t|
      t.references :conceptual_exam, index: true, null: false, foreign_key: true
      t.references :student, index: true, null: false, foreign_key: true
      t.decimal :value, null: false

      t.timestamps
    end
  end
end