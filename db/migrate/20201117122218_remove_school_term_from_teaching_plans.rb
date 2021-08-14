class RemoveSchoolTermFromTeachingPlans < ActiveRecord::Migration
  def change
    remove_column :teaching_plans, :school_term
  end
end
