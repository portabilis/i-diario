class CreateGroupedTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    create_view :grouped_teacher_discipline_classrooms
  end
end
