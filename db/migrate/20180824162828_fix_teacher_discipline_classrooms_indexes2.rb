class FixTeacherDisciplineClassroomsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :teacher_discipline_classrooms, name: :idx_teacher_discipline_classrooms_all_fks, algorithm: :concurrently
    remove_index :teacher_discipline_classrooms, name: :idx_teacher_discipline_classrooms_two_fks, algorithm: :concurrently
    remove_index :teacher_discipline_classrooms, column: [:discipline_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :teacher_discipline_classrooms, column: [:classroom_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :teacher_discipline_classrooms, column: [:teacher_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :teacher_discipline_classrooms, [:discipline_id, :classroom_id, :teacher_id], name: :idx_teacher_discipline_classrooms_all_fks, algorithm: :concurrently
    add_index :teacher_discipline_classrooms, [:discipline_id, :teacher_id], name: :idx_teacher_discipline_classrooms_two_fks, algorithm: :concurrently
    add_index :teacher_discipline_classrooms, :discipline_id, algorithm: :concurrently
    add_index :teacher_discipline_classrooms, :classroom_id, algorithm: :concurrently
    add_index :teacher_discipline_classrooms, :teacher_id, algorithm: :concurrently
  end
end
