class AddChangedAtToTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    add_column :teacher_discipline_classrooms, :changed_at, :string
  end
end
