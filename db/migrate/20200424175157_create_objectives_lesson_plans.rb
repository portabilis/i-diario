class CreateObjectivesLessonPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :objectives_lesson_plans do |t|
      t.references :objective, null: false, foreign_key: true
      t.references :lesson_plan, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
