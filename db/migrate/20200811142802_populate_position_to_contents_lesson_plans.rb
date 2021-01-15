class PopulatePositionToContentsLessonPlans < ActiveRecord::Migration
  def change
    execute 'UPDATE contents_lesson_plans SET position = id'
  end
end
