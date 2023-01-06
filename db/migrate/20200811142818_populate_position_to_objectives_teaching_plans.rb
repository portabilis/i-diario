class PopulatePositionToObjectivesTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    execute 'UPDATE objectives_teaching_plans SET position = id'
  end
end
