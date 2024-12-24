class CreateDescriptiveExamStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :descriptive_exam_students do |t|
       t.references :descriptive_exam, index: true, null: false, foreign_key: true
       t.references :student, index: true, null: false, foreign_key: true
       t.text :value, null: false

       t.timestamps
    end
  end
end