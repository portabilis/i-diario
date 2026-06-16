class AddIndexToObjectivesLessonPlans < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_objectives_lesson_plans_on_lesson_plan_and_objective'.freeze

  def up
    return if index_exists?(:objectives_lesson_plans, %i[lesson_plan_id objective_id], name: INDEX_NAME)

    add_index :objectives_lesson_plans, %i[lesson_plan_id objective_id],
              name: INDEX_NAME, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:objectives_lesson_plans, %i[lesson_plan_id objective_id], name: INDEX_NAME)

    remove_index :objectives_lesson_plans, name: INDEX_NAME, algorithm: :concurrently
  end
end
