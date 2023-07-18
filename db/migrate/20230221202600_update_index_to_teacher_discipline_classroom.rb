class UpdateIndexToTeacherDisciplineClassroom < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :teacher_discipline_classrooms, name: 'idx_unique_not_discarded_teacher_discipline_classrooms'

    add_index :teacher_discipline_classrooms, [:api_code, :teacher_id, :classroom_id, :discipline_id, :year, :grade_id],
              name: 'idx_unique_not_discarded_teacher_discipline_classrooms', unique: true,
              algorithm: :concurrently
  end
end
