class AddDiscardedAtToConceptualExam < ActiveRecord::Migration[4.2]
  def up
    add_column :conceptual_exams, :discarded_at, :datetime
    add_index :conceptual_exams, :discarded_at
  end

  def down
    remove_column :conceptual_exams, :discarded_at
  end
end
