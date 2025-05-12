class AddSchoolTermTypeToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_reference :teaching_plans, :school_term_type, index: true, foreign_key: true
  end
end
