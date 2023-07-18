class UpdateThematicUnitOfLearningObjectivesAndSkills < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Matéria e energia' WHERE code = 'EF07CI01';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Matéria e energia' WHERE code = 'EF07CI02';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Matéria e energia' WHERE code = 'EF07CI03';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Matéria e energia' WHERE code = 'EF07CI04';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Matéria e energia' WHERE code = 'EF07CI05';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Matéria e energia' WHERE code = 'EF07CI06';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Vida e evolução' WHERE code = 'EF07CI07';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Vida e evolução' WHERE code = 'EF07CI08';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Vida e evolução' WHERE code = 'EF07CI09';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Vida e evolução' WHERE code = 'EF07CI10';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Vida e evolução' WHERE code = 'EF07CI11';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Terra e Universo' WHERE code = 'EF07CI12';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Terra e Universo' WHERE code = 'EF07CI13';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Terra e Universo' WHERE code = 'EF07CI14';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Terra e Universo' WHERE code = 'EF07CI15';
      UPDATE learning_objectives_and_skills SET thematic_unit = 'Terra e Universo' WHERE code = 'EF07CI16';
    SQL
  end

  def down
    execute <<-SQL
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI01';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI02';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI03';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI04';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI05';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI06';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI07';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI08';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI09';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI10';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI11';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI12';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI13';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI14';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI15';
      UPDATE learning_objectives_and_skills SET thematic_unit = '' WHERE code = 'EF07CI16';
    SQL
  end
end
