class AddCurriculumAdaptationToLessonPlans < ActiveRecord::Migration[5.0]
  def change
    add_column :lesson_plans, :curriculum_adaptation, :text
  end
end
