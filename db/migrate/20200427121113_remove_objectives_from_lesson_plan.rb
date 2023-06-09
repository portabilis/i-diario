class RemoveObjectivesFromLessonPlan < ActiveRecord::Migration[4.2]
  def change
    remove_column :lesson_plans, :objectives, :text
  end
end
