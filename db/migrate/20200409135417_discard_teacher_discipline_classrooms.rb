class DiscardTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    Classroom.unscoped.discarded.each do |c|
      c.teacher_discipline_classrooms.discard_all
    end
  end
end
