class AddIndexActiveAndDiscardedAtToTeacherDisciplineClassroom < ActiveRecord::Migration
  def change
    add_index :teacher_discipline_classrooms, [:active, :discarded_at]
  end
end
