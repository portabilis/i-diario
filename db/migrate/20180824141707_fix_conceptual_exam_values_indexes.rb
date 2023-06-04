class FixConceptualExamValuesIndexes < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :conceptual_exam_values, name: :idx_conceptual_exam_values_discipline_fk
    remove_index :conceptual_exam_values, name: :idx_conceptual_exam_values_discipline_and_exam_fk
    remove_index :conceptual_exam_values, name: :idx_conceptual_exam_values_exam_fk
    remove_index :conceptual_exam_values, name: :unique_index_on_conceptual_exam_values

    add_index :conceptual_exam_values, :discipline_id, where: "deleted_at IS NULL", algorithm: :concurrently, name: :idx_conceptual_exam_values_discipline_fk
    add_index :conceptual_exam_values, :conceptual_exam_id, where: "deleted_at IS NULL", algorithm: :concurrently, name: :idx_conceptual_exam_values_exam_fk
    add_index :conceptual_exam_values, [:discipline_id, :conceptual_exam_id], where: "deleted_at IS NULL", algorithm: :concurrently, name: :idx_conceptual_exam_values_discipline_and_exam_fk
    add_index :conceptual_exam_values, [:conceptual_exam_id, :discipline_id], where: "deleted_at IS NULL", unique: true, name: :unique_index_on_conceptual_exam_values
  end
end
