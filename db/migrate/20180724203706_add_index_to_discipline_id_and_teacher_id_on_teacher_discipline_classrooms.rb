class AddIndexToDisciplineIdAndTeacherIdOnTeacherDisciplineClassrooms < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :teacher_discipline_classrooms, [:discipline_id, :teacher_id], algorithm: :concurrently, name: :idx_teacher_discipline_classrooms_two_fks
  end
end
