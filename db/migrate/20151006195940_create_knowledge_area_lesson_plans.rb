class CreateKnowledgeAreaLessonPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :knowledge_area_lesson_plans do |t|
      t.references :lesson_plan, index: { unique: true }, null: false
    end

    add_foreign_key :knowledge_area_lesson_plans, :lesson_plans
  end
end
