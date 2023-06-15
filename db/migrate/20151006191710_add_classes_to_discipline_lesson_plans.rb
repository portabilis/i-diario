class AddClassesToDisciplineLessonPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :discipline_lesson_plans, :classes, :integer, array: true, default: []
  end
end
