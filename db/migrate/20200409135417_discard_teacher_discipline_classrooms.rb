class DiscardTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    Classroom.unscoped.discarded.each do |c|
      c.teacher_discipline_classrooms.each { |tdc| tdc.delay(:discard) }
    end
  end
end
