class AddValidatedToTeachingPlans < ActiveRecord::Migration
  def change
    add_column :teaching_plans, :validated, :boolean
  end
end
