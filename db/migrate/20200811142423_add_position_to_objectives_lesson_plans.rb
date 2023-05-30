class AddPositionToObjectivesLessonPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :objectives_lesson_plans, :position, :integer, null: true
  end
end
