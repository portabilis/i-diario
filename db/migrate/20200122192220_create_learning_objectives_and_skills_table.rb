class CreateLearningObjectivesAndSkillsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :learning_objectives_and_skills do |t|
      t.string :code, null: false, limit: 15, unique: true
      t.text :description, null: false
      t.string :step, null: false
      t.string :field_of_experience, null: true

      t.timestamps
    end
  end
end
