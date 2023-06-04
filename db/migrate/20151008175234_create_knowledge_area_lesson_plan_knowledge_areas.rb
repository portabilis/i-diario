class CreateKnowledgeAreaLessonPlanKnowledgeAreas < ActiveRecord::Migration[4.2]
  def change
    create_table :knowledge_area_lesson_plan_knowledge_areas do |t|
      t.references :knowledge_area_lesson_plan, null: false
      t.references :knowledge_area, null: false
    end

    add_index :knowledge_area_lesson_plan_knowledge_areas,
      [:knowledge_area_lesson_plan_id, :knowledge_area_id],
      unique: true,
      name: 'index_knowledge_areas_on_lesson_plan_id_and_knowledge_area_id'

    add_foreign_key :knowledge_area_lesson_plan_knowledge_areas,
      :knowledge_area_lesson_plans,
      name: 'knowledge_area_lesson_plans_knowledge_area_lesson_plan_id_fk'
      
    add_foreign_key :knowledge_area_lesson_plan_knowledge_areas, :knowledge_areas
  end
end
