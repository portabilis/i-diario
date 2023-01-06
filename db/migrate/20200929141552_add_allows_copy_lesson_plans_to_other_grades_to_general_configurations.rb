class AddAllowsCopyLessonPlansToOtherGradesToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :allows_copy_lesson_plans_to_other_grades, :boolean, default: false
  end
end
