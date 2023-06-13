class PopulatePositionToObjectivesLessonPlans < ActiveRecord::Migration[4.2]
  def change
    execute 'UPDATE objectives_lesson_plans SET position = id'
  end
end
