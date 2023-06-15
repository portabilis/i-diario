class CreateComplementaryExamStudents < ActiveRecord::Migration[4.2]
  def change
    create_table :complementary_exam_students do |t|
      t.decimal :score, null: true

      t.references :complementary_exam, index: { name: 'index_on_complementary_exam_id' }, null: false
      t.references :student, index: true, null: false
    end

    add_foreign_key :complementary_exam_students, :complementary_exams
    add_foreign_key :complementary_exam_students, :students

    add_index(
      :complementary_exam_students,
      [:complementary_exam_id, :student_id],
      name: 'idx_unique_complementary_exam_students',
      unique: true
    )
  end
end
