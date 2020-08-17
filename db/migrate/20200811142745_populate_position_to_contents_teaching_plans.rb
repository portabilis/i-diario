class PopulatePositionToContentsTeachingPlans < ActiveRecord::Migration
  def change
    execute 'UPDATE contents_teaching_plans SET position = id'
  end
end
