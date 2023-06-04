class RemoveUnneededIdxConceptualExamValuesExamFk < ActiveRecord::Migration[4.2]
  def up
    remove_index :conceptual_exam_values, name: "idx_conceptual_exam_values_exam_fk"
  end

  def down
    execute %{
      CREATE INDEX idx_conceptual_exam_values_exam_fk ON public.conceptual_exam_values USING btree (conceptual_exam_id);
    }
  end
end
