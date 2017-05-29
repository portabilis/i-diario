class RemoveUnityIdFromLessonPlans < ActiveRecord::Migration
  def change
    remove_column :lesson_plans, :unity_id, :integer
  end
end
