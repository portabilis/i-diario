class AddTeacherIdToTeachingPlans < ActiveRecord::Migration
  def change
    add_reference :teaching_plans, :teacher, index: true, foreign_key: true
  end
end
