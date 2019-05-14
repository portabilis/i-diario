class AddDiscardedAtToConceptualExam < ActiveRecord::Migration
  def change
    add_column :conceptual_exams, :discarded_at, :datetime
    add_index :conceptual_exams, :discarded_at
  end
end
