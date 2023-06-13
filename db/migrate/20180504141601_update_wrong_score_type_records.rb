class UpdateWrongScoreTypeRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE teacher_discipline_classrooms
      SET score_type = null
      WHERE score_type = '0';
    SQL
  end
end
