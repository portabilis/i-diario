class CreateDisciplineLessonPlans < ActiveRecord::Migration[4.2]
  def change
    create_table :discipline_lesson_plans do |t|
      t.references :lesson_plan, index: { unique: true }, null: false
      t.references :discipline, index: true, null: false
    end

    add_foreign_key :discipline_lesson_plans, :lesson_plans
    add_foreign_key :discipline_lesson_plans, :disciplines
  end
end
