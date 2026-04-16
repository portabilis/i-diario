class RebalanceLessonPlansIndexes < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    add_index :lesson_plans, :teacher_id, algorithm: :concurrently
    add_index :lesson_plans, [:classroom_id, :start_at], algorithm: :concurrently
    remove_index :lesson_plans, :school_calendar_id, algorithm: :concurrently
  end

  def down
    add_index :lesson_plans, :school_calendar_id, algorithm: :concurrently
    remove_index :lesson_plans, [:classroom_id, :start_at], algorithm: :concurrently
    remove_index :lesson_plans, :teacher_id, algorithm: :concurrently
  end
end
