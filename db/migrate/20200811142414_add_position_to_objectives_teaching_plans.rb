class AddPositionToObjectivesTeachingPlans < ActiveRecord::Migration
  def change
    add_column :objectives_teaching_plans, :position, :integer, null: true
  end
end
