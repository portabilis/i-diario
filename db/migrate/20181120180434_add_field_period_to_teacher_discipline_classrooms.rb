class AddFieldPeriodToTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    add_column :teacher_discipline_classrooms, :period, :integer
  end
end
