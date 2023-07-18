class AddColumnSpecificAreaToTeacherDisciplineClassroom < ActiveRecord::Migration[4.2]
  def change
    add_column :teacher_discipline_classrooms, :specific_area, :integer
  end
end
