class AddExperienceFieldsToKnowledgeAreaLessonPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :knowledge_area_lesson_plans, :experience_fields, :string
  end
end
