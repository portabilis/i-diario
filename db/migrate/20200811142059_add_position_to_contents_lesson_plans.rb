class AddPositionToContentsLessonPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :contents_lesson_plans, :position, :integer, null: true
  end
end
