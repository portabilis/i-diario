class CreateContentsLessonPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :contents_lesson_plans do |t|
      t.integer :content_id, null: false, index: true
      t.integer :lesson_plan_id, null: false, index: true
    end
    add_foreign_key :contents_lesson_plans, :contents
    add_foreign_key :contents_lesson_plans, :lesson_plans
  end
end
