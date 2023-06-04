class RemoveUnneededIndexOnComplementaryExamId < ActiveRecord::Migration[4.2]
  def up
    remove_index :complementary_exam_students, name: "index_on_complementary_exam_id"
  end

  def down
    execute %{
      CREATE INDEX index_on_complementary_exam_id ON public.complementary_exam_students USING btree (complementary_exam_id);
    }
  end
end
