class AddUniqueIndexToTeacherDisciplineClassrooms < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :teacher_discipline_classrooms, [:teacher_id, :discipline_id, :classroom_id, :year, :period],
              name: 'idx_unique_teacher_discipline_classrooms', unique: true, algorithm: :concurrently
  end
end
