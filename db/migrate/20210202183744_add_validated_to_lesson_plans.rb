class AddValidatedToLessonPlans < ActiveRecord::Migration
  def change
    add_column :lesson_plans, :validated, :boolean
  end
end
