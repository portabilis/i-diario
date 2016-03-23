class AddColumnSpecificAreaToTeacherDisciplineClassroom < ActiveRecord::Migration
  def change
    add_column :teacher_discipline_classrooms, :specific_area, :integer
  end
end
