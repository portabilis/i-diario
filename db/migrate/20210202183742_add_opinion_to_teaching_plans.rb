class AddOpinionToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :teaching_plans, :opinion, :text
  end
end
