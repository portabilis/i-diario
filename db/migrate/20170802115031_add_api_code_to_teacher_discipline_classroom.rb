class AddApiCodeToTeacherDisciplineClassroom < ActiveRecord::Migration
  def change
    add_column :teacher_discipline_classrooms, :api_code, :string
  end
end
