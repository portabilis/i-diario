class AddColumnGradesToLearningObjectivesAndSkill < ActiveRecord::Migration
  def change
    add_column :learning_objectives_and_skills, :grades, :string, array: true, default: []
  end
end
