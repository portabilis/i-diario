class AddPositionToObjectivesTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :objectives_teaching_plans, :position, :integer, null: true
  end
end
