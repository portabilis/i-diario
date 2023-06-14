class AddUniqueIndexToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :teacher_discipline_classrooms, [:api_code, :teacher_id, :classroom_id, :discipline_id],
              name: 'idx_unique_teacher_discipline_classrooms', unique: true, algorithm: :concurrently
  end
end
