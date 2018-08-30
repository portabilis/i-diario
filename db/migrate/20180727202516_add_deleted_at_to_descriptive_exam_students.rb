class AddDeletedAtToDescriptiveExamStudents < ActiveRecord::Migration
  def change
    add_column :descriptive_exam_students, :deleted_at, :datetime
    add_index :descriptive_exam_students, :deleted_at
  end
end
