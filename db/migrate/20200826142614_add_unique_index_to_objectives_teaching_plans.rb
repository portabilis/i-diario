class AddUniqueIndexToObjectivesTeachingPlans < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :objectives_teaching_plans, [:objective_id, :teaching_plan_id],
              name: 'idx_objectives_teaching_plans', unique: true, algorithm: :concurrently
  end
end
