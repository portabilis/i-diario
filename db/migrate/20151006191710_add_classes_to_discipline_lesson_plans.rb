class Add***REMOVED***ToDisciplineLessonPlans < ActiveRecord::Migration
  def change
    add_column :discipline_lesson_plans, :classes, :integer, array: true, default: []
  end
end
