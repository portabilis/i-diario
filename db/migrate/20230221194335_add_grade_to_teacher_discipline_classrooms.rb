class AddGradeToTeacherDisciplineClassrooms < ActiveRecord::Migration
  def up
    add_reference :teacher_discipline_classrooms, :grade, index: true, foreign_key: true
  end

  def down
    add_reference :teacher_discipline_classrooms, :grade, index: true, foreign_key: true
  end
end
