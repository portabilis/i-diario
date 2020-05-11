class RemoveObjectivesFromTeachingPlan < ActiveRecord::Migration
  def change
    remove_column :teaching_plans, :objectives, :text
  end
end
