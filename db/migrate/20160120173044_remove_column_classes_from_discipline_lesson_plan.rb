class RemoveColumnClassesFromDisciplineLessonPlan < ActiveRecord::Migration[4.2]
  def change
    remove_column :discipline_lesson_plans, :classes, :integer
  end
end
