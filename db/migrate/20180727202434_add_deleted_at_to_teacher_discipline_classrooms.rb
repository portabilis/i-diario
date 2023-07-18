class AddDeletedAtToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :teacher_discipline_classrooms, :deleted_at, :datetime
    add_index :teacher_discipline_classrooms, :deleted_at
  end
end
