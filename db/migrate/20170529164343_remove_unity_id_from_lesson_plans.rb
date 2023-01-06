class RemoveUnityIdFromLessonPlans < ActiveRecord::Migration[4.2]
  def change
    remove_column :lesson_plans, :unity_id, :integer
  end
end
