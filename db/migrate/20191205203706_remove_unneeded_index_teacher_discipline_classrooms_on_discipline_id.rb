class RemoveUnneededIndexTeacherDisciplineClassroomsOnDisciplineId < ActiveRecord::Migration[4.2]
  def change
    remove_index :teacher_discipline_classrooms, name: "index_teacher_discipline_classrooms_on_discipline_id"
  end

  def down
    execute %{
      CREATE INDEX index_teacher_discipline_classrooms_on_discipline_id ON public.teacher_discipline_classrooms USING btree (discipline_id);
    }
  end
end
