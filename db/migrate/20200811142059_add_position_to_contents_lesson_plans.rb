class AddPositionToContentsLessonPlans < ActiveRecord::Migration
  def change
    add_column :contents_lesson_plans, :position, :integer, null: true
  end
end
