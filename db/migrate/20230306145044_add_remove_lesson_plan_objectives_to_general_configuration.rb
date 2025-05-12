class AddRemoveLessonPlanObjectivesToGeneralConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :remove_lesson_plan_objectives, :boolean, default: false
  end
end
