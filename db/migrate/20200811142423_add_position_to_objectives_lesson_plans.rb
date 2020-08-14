class AddPositionToObjectivesLessonPlans < ActiveRecord::Migration
  def change
    add_column :objectives_lesson_plans, :position, :integer, null: true
  end
end
