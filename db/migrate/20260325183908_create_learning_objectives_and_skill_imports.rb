class CreateLearningObjectivesAndSkillImports < ActiveRecord::Migration[5.0]
  def change
    create_table :learning_objectives_and_skill_imports do |t|
      t.references :user, foreign_key: true, null: false
      t.string :step, null: false
      t.string :import_mode, null: false
      t.integer :imported_count, default: 0, null: false
      t.integer :removed_count, default: 0, null: false

      t.timestamps
    end
  end
end
