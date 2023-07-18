class AddNotDiscartedTeacherDisciplineClassroomsIdx < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :teacher_discipline_classrooms, [:api_code, :teacher_id, :classroom_id, :discipline_id],
              name: 'idx_unique_not_discarded_teacher_discipline_classrooms', unique: true,
              algorithm: :concurrently, where: 'discarded_at IS NULL'
  end
end
