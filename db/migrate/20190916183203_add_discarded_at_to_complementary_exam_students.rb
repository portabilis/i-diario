class AddDiscardedAtToComplementaryExamStudents < ActiveRecord::Migration
  def change
    add_column :complementary_exam_students, :discarded_at, :datetime
  end
end
