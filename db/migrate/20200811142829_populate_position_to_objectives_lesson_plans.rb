class PopulatePositionToObjectivesLessonPlans < ActiveRecord::Migration
  def change
    execute 'UPDATE objectives_lesson_plans SET position = id'
  end
end
