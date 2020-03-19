class AddExperienceFieldsToKnowledgeAreaLessonPlans < ActiveRecord::Migration
  def change
    add_column :knowledge_area_lesson_plans, :experience_fields, :string
  end
end
