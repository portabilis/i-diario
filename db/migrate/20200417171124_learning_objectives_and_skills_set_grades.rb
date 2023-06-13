class LearningObjectivesAndSkillsSetGrades < ActiveRecord::Migration[4.2]
  def up
    execute File.read(Rails.root.join('db', 'seeds', 'learning_objectives_and_skills_set_grades.sql'))
  end

  def down
    execute <<-SQL
      UPDATE learning_objectives_and_skills SET grades = '{}';
    SQL
  end
end
