class PopulatePositionToContentsTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    execute 'UPDATE contents_teaching_plans SET position = id'
  end
end
