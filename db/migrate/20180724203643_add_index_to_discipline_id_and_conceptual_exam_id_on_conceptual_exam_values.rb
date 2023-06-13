class AddIndexToDisciplineIdAndConceptualExamIdOnConceptualExamValues < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :conceptual_exam_values, [:discipline_id, :conceptual_exam_id], algorithm: :concurrently, name: :idx_conceptual_exam_values_discipline_and_exam_fk
  end
end
