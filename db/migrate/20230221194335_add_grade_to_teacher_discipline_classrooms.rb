class AddGradeToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def up
    add_reference :teacher_discipline_classrooms, :grade, index: true, foreign_key: true
  end

  def down
    remove_reference :teacher_discipline_classrooms, :grade, index: true, foreign_key: true
  end
end
