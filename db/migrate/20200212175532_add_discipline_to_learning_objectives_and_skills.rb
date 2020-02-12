class AddDisciplineToLearningObjectivesAndSkills < ActiveRecord::Migration
  def change
    add_column :learning_objectives_and_skills, :discipline, :string
  end
end
