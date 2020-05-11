class RemoveObjectivesFromLessonPlan < ActiveRecord::Migration
  def change
    remove_column :lesson_plans, :objectives, :text
  end
end
