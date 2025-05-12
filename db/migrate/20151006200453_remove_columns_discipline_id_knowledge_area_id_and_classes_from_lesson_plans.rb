class RemoveColumnsDisciplineIdKnowledgeAreaIdAndClassesFromLessonPlans < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      INSERT INTO discipline_lesson_plans(lesson_plan_id, discipline_id, classes)
      SELECT id, discipline_id, classes FROM lesson_plans WHERE discipline_id IS NOT NULL ORDER BY id;

      INSERT INTO knowledge_area_lesson_plans(lesson_plan_id)
      SELECT id FROM lesson_plans WHERE discipline_id IS NULL ORDER BY id;
    SQL

    remove_column :lesson_plans, :discipline_id
    remove_column :lesson_plans, :knowledge_area_id
    remove_column :lesson_plans, :classes
  end
end
