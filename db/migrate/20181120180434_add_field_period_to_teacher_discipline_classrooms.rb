class AddFieldPeriodToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :teacher_discipline_classrooms, :period, :integer
  end
end
