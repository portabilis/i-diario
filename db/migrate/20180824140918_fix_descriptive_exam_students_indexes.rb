class FixDescriptiveExamStudentsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :descriptive_exam_students, :descriptive_exam_id
    remove_index :descriptive_exam_students, :student_id

    add_index :descriptive_exam_students, :descriptive_exam_id, where: "deleted_at IS NULL"
    add_index :descriptive_exam_students, :student_id, where: "deleted_at IS NULL"
  end
end
