class PopulatePositionToObjectivesTeachingPlans < ActiveRecord::Migration
  def change
    execute 'UPDATE objectives_teaching_plans SET position = id'
  end
end
