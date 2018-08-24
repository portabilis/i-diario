class AddDeletedAtToConceptualExams < ActiveRecord::Migration
  def change
    add_column :conceptual_exams, :deleted_at, :datetime
    add_index :conceptual_exams, :deleted_at
  end
end
