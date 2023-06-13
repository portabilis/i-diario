class FixConceptualExamValuesIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :conceptual_exam_values, name: :idx_conceptual_exam_values_discipline_fk, algorithm: :concurrently
    remove_index :conceptual_exam_values, name: :idx_conceptual_exam_values_exam_fk, algorithm: :concurrently
    remove_index :conceptual_exam_values, name: :idx_conceptual_exam_values_discipline_and_exam_fk, algorithm: :concurrently
    remove_index :conceptual_exam_values, name: :unique_index_on_conceptual_exam_values, algorithm: :concurrently

    add_index :conceptual_exam_values, :discipline_id, algorithm: :concurrently, name: :idx_conceptual_exam_values_discipline_fk
    add_index :conceptual_exam_values, :conceptual_exam_id, algorithm: :concurrently, name: :idx_conceptual_exam_values_exam_fk
    add_index :conceptual_exam_values, [:discipline_id, :conceptual_exam_id], algorithm: :concurrently, name: :idx_conceptual_exam_values_discipline_and_exam_fk
    add_index :conceptual_exam_values, [:conceptual_exam_id, :discipline_id], unique: true, name: :unique_index_on_conceptual_exam_values, algorithm: :concurrently
  end
end
