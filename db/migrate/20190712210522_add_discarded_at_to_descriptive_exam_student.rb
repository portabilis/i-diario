class AddDiscardedAtToDescriptiveExamStudent < ActiveRecord::Migration[4.2]
  def up
    add_column :descriptive_exam_students, :discarded_at, :datetime
    add_index :descriptive_exam_students, :discarded_at
  end

  def down
    remove_column :descriptive_exam_students, :discarded_at
  end
end
