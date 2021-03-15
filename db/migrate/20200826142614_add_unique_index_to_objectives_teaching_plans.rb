class AddUniqueIndexToObjectivesTeachingPlans < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :objectives_teaching_plans, [:objective_id, :teaching_plan_id],
              name: 'idx_objectives_teaching_plans', unique: true, algorithm: :concurrently
  end
end
