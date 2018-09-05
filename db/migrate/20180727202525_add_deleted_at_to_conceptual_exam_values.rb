class AddDeletedAtToConceptualExamValues < ActiveRecord::Migration
  def change
    add_column :conceptual_exam_values, :deleted_at, :datetime
    add_index :conceptual_exam_values, :deleted_at
  end
end
