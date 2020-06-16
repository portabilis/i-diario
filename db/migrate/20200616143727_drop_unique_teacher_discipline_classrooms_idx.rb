class DropUniqueTeacherDisciplineClassroomsIdx < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_index :teacher_discipline_classrooms, name: 'idx_unique_teacher_discipline_classrooms',
                                                 algorithm: :concurrently
  end

  def down
    add_index :teacher_discipline_classrooms, [:api_code, :teacher_id, :classroom_id, :discipline_id],
              name: 'idx_unique_teacher_discipline_classrooms', unique: true, algorithm: :concurrently
  end
end
