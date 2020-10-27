class AddAllowsCopyLessonPlansToOtherGradesToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :allows_copy_lesson_plans_to_other_grades, :boolean, default: false
  end
end
