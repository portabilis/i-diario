class AddDiscardedAtToTeacherDisciplineClassroom < ActiveRecord::Migration
  def change
    add_column :teacher_discipline_classrooms, :discarded_at, :datetime
    add_index :teacher_discipline_classrooms, :discarded_at
  end
end
