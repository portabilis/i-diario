class RenamePermissionLessonPlanReports < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE role_permissions SET feature = 'discipline_lesson_plan_report' WHERE feature = 'lesson_plan_discipline_report';
      UPDATE role_permissions SET feature = 'knowledge_area_lesson_plan_report' WHERE feature = 'lesson_plan_knowledge_area_report';
    SQL
  end
end
