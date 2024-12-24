class FixDescriptiveExamStudentsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :descriptive_exam_students, column: [:descriptive_exam_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :descriptive_exam_students, column: [:student_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :descriptive_exam_students, :descriptive_exam_id, algorithm: :concurrently
    add_index :descriptive_exam_students, :student_id, algorithm: :concurrently
  end
end
