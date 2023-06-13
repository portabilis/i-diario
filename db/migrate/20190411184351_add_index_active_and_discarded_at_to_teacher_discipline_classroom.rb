class AddIndexActiveAndDiscardedAtToTeacherDisciplineClassroom < ActiveRecord::Migration[4.2]
  def change
    add_index :teacher_discipline_classrooms, [:active, :discarded_at]
  end
end
