class RemoveUnneededIdxConceptualExamValuesDisciplineFk < ActiveRecord::Migration
  def up
    remove_index :conceptual_exam_values, name: "idx_conceptual_exam_values_discipline_fk"
  end

  def down
    execute %{
      CREATE INDEX idx_conceptual_exam_values_discipline_fk ON public.conceptual_exam_values USING btree (discipline_id);
    }
  end
end
