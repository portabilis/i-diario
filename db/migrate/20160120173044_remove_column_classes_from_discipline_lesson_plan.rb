class RemoveColumnClassesFromDisciplineLessonPlan < ActiveRecord::Migration
  def change
    remove_column :discipline_lesson_plans, :classes, :integer
  end
end
