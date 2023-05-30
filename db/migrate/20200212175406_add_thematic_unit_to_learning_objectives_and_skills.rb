class AddThematicUnitToLearningObjectivesAndSkills < ActiveRecord::Migration[4.2]
  def change
    add_column :learning_objectives_and_skills, :thematic_unit, :string
  end
end
