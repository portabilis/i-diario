class RemoveObjectivesFromTeachingPlan < ActiveRecord::Migration[4.2]
  def change
    remove_column :teaching_plans, :objectives, :text
  end
end
