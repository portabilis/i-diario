class FixTeacherDisciplineClassroomsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :teacher_discipline_classrooms, name: :idx_teacher_discipline_classrooms_all_fks
    remove_index :teacher_discipline_classrooms, name: :idx_teacher_discipline_classrooms_two_fks
    remove_index :teacher_discipline_classrooms, :discipline_id
    remove_index :teacher_discipline_classrooms, :classroom_id
    remove_index :teacher_discipline_classrooms, :teacher_id

    add_index :teacher_discipline_classrooms, [:discipline_id, :classroom_id, :teacher_id], where: "deleted_at IS NULL", name: :idx_teacher_discipline_classrooms_all_fks
    add_index :teacher_discipline_classrooms, [:discipline_id, :teacher_id], where: "deleted_at IS NULL", name: :idx_teacher_discipline_classrooms_two_fks
    add_index :teacher_discipline_classrooms, :discipline_id, where: "deleted_at IS NULL"
    add_index :teacher_discipline_classrooms, :classroom_id, where: "deleted_at IS NULL"
    add_index :teacher_discipline_classrooms, :teacher_id, where: "deleted_at IS NULL"
  end
end
