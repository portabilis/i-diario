class AddTeacherIdToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_reference :teaching_plans, :teacher, index: true, foreign_key: true
  end
end
