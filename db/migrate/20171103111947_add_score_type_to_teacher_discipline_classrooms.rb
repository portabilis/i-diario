class AddScoreTypeToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :teacher_discipline_classrooms, :score_type, :string
  end
end
