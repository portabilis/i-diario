class AddValidatedToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :teaching_plans, :validated, :boolean
  end
end
