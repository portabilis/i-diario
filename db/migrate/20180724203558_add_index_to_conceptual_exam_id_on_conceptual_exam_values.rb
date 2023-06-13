class AddIndexToConceptualExamIdOnConceptualExamValues < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :conceptual_exam_values, :conceptual_exam_id, algorithm: :concurrently, name: :idx_conceptual_exam_values_exam_fk
  end
end
