class RemoveSchoolTermTypeFromTeachingPlans < ActiveRecord::Migration
  def change
    remove_column :teaching_plans, :school_term_type
  end
end
