class RanameColumnsOnLessonPlans < ActiveRecord::Migration[4.2]
  def change
    change_table :lesson_plans do |t|
     t.rename :content_date, :lesson_plan_date
     t.rename :theme, :contents
     t.rename :description, :activities
     t.rename :goals, :objectives
     t.rename :means, :resources
    end
  end
end
