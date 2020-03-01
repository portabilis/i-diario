class AddExperienceFieldsToKnowledgeAreaTeachingPlans < ActiveRecord::Migration
  def change
    add_column :knowledge_area_teaching_plans, :experience_fields, :string
  end
end
