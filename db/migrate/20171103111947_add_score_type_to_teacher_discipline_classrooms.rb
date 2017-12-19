class AddScoreTypeToTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    add_column :teacher_discipline_classrooms, :score_type, :string
  end
end
