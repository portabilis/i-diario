class AddOpinionToTeachingPlans < ActiveRecord::Migration
  def change
    add_column :teaching_plans, :opinion, :text
  end
end
