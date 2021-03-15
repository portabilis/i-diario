class AddUniqueIndexToContentsTeachingPlans < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :contents_teaching_plans, [:content_id, :teaching_plan_id],
              name: 'idx_contents_teaching_plans', unique: true, algorithm: :concurrently
  end
end
