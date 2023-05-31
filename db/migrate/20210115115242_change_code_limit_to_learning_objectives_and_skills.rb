class ChangeCodeLimitToLearningObjectivesAndSkills < ActiveRecord::Migration[4.2]
  def change
    change_column :learning_objectives_and_skills, :code, :string, limit: 50
  end
end
