class AddDeletedAtToConceptualExams < ActiveRecord::Migration[4.2]
  def change
    add_column :conceptual_exams, :deleted_at, :datetime
    add_index :conceptual_exams, :deleted_at
  end
end
