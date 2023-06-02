class AdjustScoreTypeToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE teacher_discipline_classrooms
         SET score_type = 'X'
       WHERE score_type = '2';

      UPDATE teacher_discipline_classrooms
         SET score_type = '2'
       WHERE score_type = '1';

      UPDATE teacher_discipline_classrooms
         SET score_type = '1'
       WHERE score_type = 'X';
    SQL
  end
end
