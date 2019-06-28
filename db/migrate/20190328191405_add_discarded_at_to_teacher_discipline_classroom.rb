class AddDiscardedAtToTeacherDisciplineClassroom < ActiveRecord::Migration
  def up
    add_column :teacher_discipline_classrooms, :discarded_at, :datetime
    add_index :teacher_discipline_classrooms, :discarded_at
  end

  def down
    remove_column :teacher_discipline_classrooms, :discarded_at
  end
end
